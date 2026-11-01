using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Signal.Services
{
    public class AuthTokenHandler(ApiService authService) : DelegatingHandler
    {
        private readonly ApiService apiService = authService;

        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            if (!string.IsNullOrEmpty(SessionContext.AccessToken))
            {
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", SessionContext.AccessToken);
            }

            var response = await base.SendAsync(request, cancellationToken);

            if (response.StatusCode == HttpStatusCode.Unauthorized)
            {
                string requestPath = request.RequestUri?.AbsolutePath ?? string.Empty;

                bool isAuthRequest = requestPath.Contains("/api/auth/login", StringComparison.OrdinalIgnoreCase) ||
                                    requestPath.Contains("/api/auth/refresh", StringComparison.OrdinalIgnoreCase);

                if (isAuthRequest)
                {
                    request.Headers.Remove("X-Device-Name");
                    request.Headers.Add("X-Device-Name", GetDeviceName());
                }

                if (!isAuthRequest)
                {
                    bool isRefreshed = await TryRefreshTokensAsync();

                    if (isRefreshed)
                    {
                        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", SessionContext.AccessToken);
                        response.Dispose();
                        return await base.SendAsync(request, cancellationToken);
                    }
                }
            }

            return response;
        }

        private async Task<bool> TryRefreshTokensAsync()
        {
            try
            {
                return await apiService.RefreshTokensAsync();
            }
            catch
            {
                return false;
            }
        }

        private string GetDeviceName()
        {
            string machineName = Environment.MachineName;

            if (!string.IsNullOrWhiteSpace(machineName) && machineName != "localhost")
            {
                return machineName;
            }

            string osDescription = RuntimeInformation.OSDescription;
            string architecture = RuntimeInformation.ProcessArchitecture.ToString();

            return $"{osDescription} ({architecture})";
        }
    }
}
