using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Signal.agent.Models;
using System.Text;
using System.Text.Json;
using System.Net.Sockets;
using System.Net.Http.Json;
using Signal.Server.Data.Dtos;

class Program
{
    static async Task Main(string[] args)
    {
        Console.Write("Введите IP-адрес или домен API сервера: ");
        string apiHost = Console.ReadLine()?.Trim() ?? "localhost";

        Console.Write("Введите порт API сервера: ");
        string apiPort = Console.ReadLine()?.Trim() ?? "5000";

        string baseApiUrl = $"http://{apiHost}:{apiPort}/";

        IHostBuilder hostBuilder = Host.CreateDefaultBuilder(args)
            .ConfigureServices((hostContext, services) =>
            {
                var httpClient = new HttpClient
                {
                    BaseAddress = new Uri(baseApiUrl),
                    Timeout = TimeSpan.FromSeconds(10) 
                };

                services.AddSingleton(httpClient);

                services.AddHostedService<NetworkPollingService>();
            });

        await hostBuilder.RunConsoleAsync();

    }
}

public class NetworkPollingService(HttpClient httpClient) : BackgroundService
{
    private readonly HttpClient _httpClient = httpClient;

    async Task<List<DeviceConfig>> GetConfigurationsAsync()
    {
        const string filePath = "devices.json";

        try
        {
            if (!File.Exists(filePath))
            {
                Console.WriteLine($"Файл {filePath} не найден");
                return new List<DeviceConfig>();
            }

            string jsonString = await File.ReadAllTextAsync(filePath);

            var options = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };

            List<DeviceConfig>? devices = JsonSerializer.Deserialize<List<DeviceConfig>>(jsonString, options);

            return devices ?? new List<DeviceConfig>();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Ошибка при чтении или парсинге JSON: {ex.Message}");
            return new List<DeviceConfig>();
        }
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            List<DeviceConfig> devices = await GetConfigurationsAsync();

            foreach (var device in devices)
            {
                if (stoppingToken.IsCancellationRequested) break;
                await PollDeviceAsync(device);
            }

            await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);
        }
    }

    private async Task PollDeviceAsync(DeviceConfig device)
    {
        using var tcpClient = new TcpClient();
        try
        {
            tcpClient.ReceiveTimeout = 5000;
            tcpClient.SendTimeout = 5000;

            var connectTask = tcpClient.ConnectAsync(device.Ip, 23);
            if (await Task.WhenAny(connectTask, Task.Delay(5000)) != connectTask)
            {
                Console.WriteLine($"[ОШИБКА] Таймаут подключения к IP {device.Ip}");
                return;
            }

            using var stream = tcpClient.GetStream();
            using var reader = new StreamReader(stream, Encoding.ASCII);
            using var writer = new StreamWriter(stream, Encoding.ASCII) { AutoFlush = true };

            string prompt = "(Q=Quit) Telnet-->";

            string response = await ReadUntilTimeoutOrTokenAsync(reader, "Enter name:");
            await writer.WriteLineAsync(device.Login);

            await ReadUntilTimeoutOrTokenAsync(reader, "Enter password:");
            await writer.WriteLineAsync(device.Password);

            response = await ReadUntilTimeoutOrTokenAsync(reader, prompt);
            if (!response.Contains(prompt))
            {
                Console.WriteLine($"[ОШИБКА] Не удалось войти в CLI на {device.Ip}. Неверный логин/пароль");
                return;
            }

            foreach (var param in device.Params)
            {
                await writer.WriteLineAsync(param.Command);

                string rawResult = await ReadUntilTimeoutOrTokenAsync(reader, prompt);

                string cleanedResult = ExtractValueFromResponse(rawResult);

                string finalValue = ProcessValue(cleanedResult, param);

                Console.WriteLine($"IP: {device.Ip} | Команда: {param.Command} | Итог: {finalValue}");

                var logDto = new CreateReadingLogDto
                {
                    IpAddress = device.Ip,
                    ReadingTypeIdentifier = param.Name,
                    Value = finalValue
                };

                try
                {
                    await _httpClient.PostAsJsonAsync("api/equipment/logs", logDto);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[ОШИБКА] IP: {device.Ip} | Не удалось создать лог для {param.Name} \n param={param.Name} | value={finalValue} \n {ex.Message}");
                }
            }

            await writer.WriteLineAsync("Q");
            Console.WriteLine("------");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[ОШИБКА] Исключение при опросе {device.Ip}: {ex.Message}");
        }
    }

    private async Task<string> ReadUntilTimeoutOrTokenAsync(StreamReader reader, string token)
    {
        var sb = new StringBuilder();
        char[] buffer = new char[1];

        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(5));

        try
        {
            while (!cts.Token.IsCancellationRequested)
            {
                int readCount = await reader.ReadAsync(buffer, 0, 1);
                if (readCount == 0) break; 

                sb.Append(buffer[0]);

                if (sb.ToString().Contains(token))
                {
                    break;
                }
            }
        }
        catch (ObjectDisposedException) { }
        catch (IOException) { } 

        return sb.ToString();
    }

    private string ExtractValueFromResponse(string rawResponse)
    {
        if (string.IsNullOrEmpty(rawResponse)) return string.Empty;

        int equalSignIndex = rawResponse.IndexOf('=');
        if (equalSignIndex == -1)
        {
            return rawResponse.Trim(); 
        }

        string valuePart = rawResponse.Substring(equalSignIndex + 1);

        string[] lines = valuePart.Split(new[] { "\r", "\n" }, StringSplitOptions.RemoveEmptyEntries);
        if (lines.Length > 0)
        {
            return lines[0].Trim(); 
        }

        return valuePart.Trim();
    }

    string ProcessValue(string value, ParamConfig param)
    {
        if (param.Uncorrect != null && value.Equals(param.Uncorrect, StringComparison.OrdinalIgnoreCase))
        {
            return "n/a";
        }

        if (param.Annotations != null && param.Annotations.Count > 0)
        {
            if (param.Annotations.TryGetValue(value, out var interpretedValue))
            {
                return interpretedValue;
            }
            return "n/a"; 
        }

        return value;
    }
}