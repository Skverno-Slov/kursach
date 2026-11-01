using Microsoft.EntityFrameworkCore;
using Signal.Server.Data;
using Signal.Server.Data.Dtos;
using Signal.Server.Data.Models;

namespace Signal.Server.Services
{
    public class EquipmentService(ApplicationDbContext context)
    {
        private readonly ApplicationDbContext context = context;

        public async Task<PagedLogsResponse> GetEquipmentLogsAsync(string serialNumber,
                                                                   string periodType,
                                                                   string? readingIdentifier, 
                                                                   int page = 1,
                                                                   int pageSize = 20)
        {
            var now = DateTime.UtcNow;
            DateTime? startDate = null;
            DateTime? endDate = null;

            ApplyPeriod(periodType, now, ref startDate, ref endDate);

            var availableIdentifiers = await context.ReadingLogs
                .Where(rl => rl.Equipment.SerialNumber == serialNumber)
                .Select(rl => rl.ReadingType.Identifier)
                .Distinct()
                .ToListAsync();

            var query = context.ReadingLogs
                .Where(rl => rl.Equipment.SerialNumber == serialNumber 
                && rl.Status.Name.ToLower() != "ok");

            if (startDate.HasValue) query = query.Where(rl => rl.WriteDateTime >= startDate.Value);
            if (endDate.HasValue) query = query.Where(rl => rl.WriteDateTime < endDate.Value);

            if (!string.IsNullOrEmpty(readingIdentifier))
            {
                query = query.Where(rl => rl.ReadingType.Identifier == readingIdentifier);
            }

            int totalCount = await query.CountAsync();

            var logs = await query
                .OrderByDescending(rl => rl.WriteDateTime)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(rl => new ReadingLogResponse(
                    rl.ReadingType.Name,
                    rl.Value,
                    rl.ReadingType.Unit,
                    rl.Status.Name,
                    rl.WriteDateTime
                ))
                .ToListAsync();

            return new PagedLogsResponse(logs, availableIdentifiers, totalCount);
        }

        public async Task<List<EquipmentDto>> GetEquipmentAsync()
        {
            return await context.Equipment
                .OrderBy(e => e.Model) 
                .ThenBy(e => e.Name)
                .Select(e => new EquipmentDto(
                    e.EquipmentId,
                    e.SerialNumber,
                    e.Name,
                    e.Model,
                    e.Status.Name
                )).ToListAsync();
        }

        public async Task<EquipmentResponce> GetEquipmentAsync(int page = 1, int pageSize = 10)
        {
            var equipmentCount = context.Equipment.Count();
            var equipment = await context.Equipment
                .OrderBy(e => e.Model)
                .ThenBy(e => e.Name)
                .Select(e => new EquipmentDto(
                    e.EquipmentId,
                    e.SerialNumber,
                    e.Name,
                    e.Model,
                    e.Status.Name
                )).Skip(pageSize * (page - 1)).Take(pageSize).ToListAsync();
            return new EquipmentResponce()
            {
                Equipment = equipment,
                TotalEquipment = equipmentCount
            };
        }

        public async Task<List<GraphPointResponse>> GetFullGraphDataAsync(string serialNumber, string periodType)
        {
            var now = DateTime.UtcNow;
            DateTime? startDate = null;
            DateTime? endDate = null;

            ApplyPeriod(periodType, now, ref startDate, ref endDate);

            var query = context.ReadingLogs
                .Where(rl => rl.Equipment.SerialNumber == serialNumber);

            if (startDate.HasValue) query = query.Where(rl => rl.WriteDateTime >= startDate.Value);
            if (endDate.HasValue) query = query.Where(rl => rl.WriteDateTime < endDate.Value);

            return await query
                .OrderBy(rl => rl.WriteDateTime) 
                .Select(rl => new GraphPointResponse(
                    rl.ReadingType.Identifier,
                    rl.Value, 
                    rl.WriteDateTime
                ))
                .ToListAsync();
        }

        public async Task<bool> CheckEquipmentExistsAsync(string serialNumber)
        {
            return await context.Equipment
                .AnyAsync(e => e.SerialNumber == serialNumber);
        }

        public async Task<IEnumerable<LatestReadingResponse>> GetLatestReadingsAsync(string serialNumber)
        {
            return await context.ViewLatestEquipmentReadings
                .Where(r => r.SerialNumber == serialNumber)
                .Select(r => new LatestReadingResponse(
                    r.SerialNumber,
                    r.MetricKey ?? "",
                    r.Label ?? "",
                    r.Value ?? "",
                    r.Unit,
                    r.Status ?? "ok",
                    r.Datetime,
                    r.MinValue,
                    r.MaxValue
                ))
                .ToListAsync();
        }

        public async Task<ReadingLog> AddReadingLogAsync(CreateReadingLogDto dto)
        {
            var equipmentId = context.Equipment
                .Where(e => e.IpAddress == dto.IpAddress) 
                .Select(e => e.EquipmentId)
                .FirstOrDefault();

            var equipmentExists = equipmentId != 0;

            if (!equipmentExists)
            {
                var status = await context.Statuses.FirstOrDefaultAsync(s => s.Name.ToLower() == "ok");
                if (status is null)
                    throw new InvalidDataException("Статус Ok не найден");

                var equipment = new Equipment()
                {
                    StatusId = status.StatusId,
                    IpAddress = dto.IpAddress,
                    SerialNumber = Guid.NewGuid().ToString(),
                    Name = "New Equipment",
                    Model = "Other"
                };

                await context.Equipment.AddAsync(equipment);
                await context.SaveChangesAsync();
            }

            var readingTypeId = context.ReadingTypes
                .Where(rt => rt.Identifier == dto.ReadingTypeIdentifier)
                .Select(rt => rt.ReadingTypeId)
                .FirstOrDefault();

            var readingTypeExists = readingTypeId != 0;

            if (!readingTypeExists)
            {
                var readingType = new ReadingType()
                {
                    Identifier = dto.ReadingTypeIdentifier,
                    Name = dto.ReadingTypeIdentifier
                };
                await context.ReadingTypes.AddAsync(readingType);
                await context.SaveChangesAsync();
            }

            var newLog = new ReadingLog
            {
                EquipmentId = equipmentId,
                ReadingTypeId = readingTypeId,
                StatusId = 1,
                Value = dto.Value,
                WriteDateTime = DateTime.UtcNow
            };

            if (!readingTypeExists)
            {
                var readingType = await context.ReadingTypes.FirstOrDefaultAsync(r => r.Identifier == dto.ReadingTypeIdentifier);
                if (readingType is null)
                    throw new InvalidDataException("Тип показания не найден");
                newLog.ReadingTypeId = readingType.ReadingTypeId;
            }

            if (!readingTypeExists)
            {
                var equipment = await context.Equipment.FirstOrDefaultAsync(r => r.IpAddress == dto.IpAddress);
                if (equipment is null)
                    throw new InvalidDataException("Оборудование не найдено");
                newLog.EquipmentId = equipment.EquipmentId;
            }

            await context.ReadingLogs.AddAsync(newLog);
            await context.SaveChangesAsync();

            return newLog;
        }

        public async Task<bool> DeleteEquipmentAsync(int id)
        {
            var equipment = await context.Equipment.FindAsync(id);
            if (equipment is null) 
                return false;

            try
            {
                context.Equipment.Remove(equipment);
                await context.SaveChangesAsync();
                return true;
            }
            catch
            {
                return false;
            }
        }

        public async Task<bool> UpdateEquipmentAsync(int id, EquipmentDto dto)
        {
            var equipment = await context.Equipment.FindAsync(id);
            if (equipment is null) 
                return false;

            if (equipment.SerialNumber != dto.SerialNumber)
            {
                bool loginExists = await context.Equipment.AnyAsync(u => u.SerialNumber == dto.SerialNumber);
                if (loginExists) throw new InvalidOperationException("Серийный номер уже занят");
            }

            equipment.SerialNumber = dto.SerialNumber;
            equipment.Name = dto.Name;
            equipment.Model = dto.Model;
            var status = await context.Statuses.FirstOrDefaultAsync(s => s.Name == dto.StatusName);
            if (status is not null)
                equipment.StatusId = status.StatusId;

            try
            {
                await context.SaveChangesAsync();
                return true;
            }
            catch
            {
                return false;
            }
        }

        public async Task<ReadingTypeResponce> GetReadingTypesAsync(int page, int pageSize)
        {
            var readingTypeCount = context.ReadingTypes.Count();
            var readingTypes = await context.ReadingTypes
                .Select(rt => new ReadingTypeDto() { 
                    ReadingTypeId = rt.ReadingTypeId,
                    Name = rt.Name,
                    Identifier = rt.Identifier,
                    Unit = rt.Unit,
                    MinValue = rt.MinValue,
                    MaxValue = rt.MaxValue
                }).Skip(pageSize * (page - 1)).Take(pageSize).ToListAsync();
            return new ReadingTypeResponce()
            {
                ReadingTypes = readingTypes,
                TotalReadingTypes = readingTypeCount
            };
        }

        public async Task<bool> DeleteReadingTypeAsync(int id)
        {
            var readingType = await context.ReadingTypes.FindAsync(id);
            if (readingType is null)
                return false;

            try
            {
                context.ReadingTypes.Remove(readingType);
                await context.SaveChangesAsync();
                return true;
            }
            catch
            {
                return false;
            }
        }

        public async Task<bool> UpdateReadingTypeAsync(int id, ReadingTypeDto dto)
        {
            var readingType = await context.ReadingTypes.FindAsync(id);
            if (readingType is null)
                return false;

            if (readingType.Identifier != dto.Identifier)
            {
                bool loginExists = await context.ReadingTypes.AnyAsync(u => u.Identifier == dto.Identifier);
                if (loginExists) throw new InvalidOperationException("Идентификатор уже занят");
            }

            readingType.Identifier = dto.Identifier;
            readingType.Name = dto.Name;
            readingType.Unit = dto.Unit;
            readingType.MinValue = dto.MinValue;
            readingType.MaxValue = dto.MaxValue;

            try
            {
                await context.SaveChangesAsync();
                return true;
            }
            catch
            {
                return false;
            }
        }

        private static void ApplyPeriod(string periodType, DateTime now, ref DateTime? startDate, ref DateTime? endDate)
        {
            switch (periodType.ToUpper())
            {
                case "HOUR_1":
                    startDate = now.AddHours(-1);
                    break;

                case "TODAY":
                    startDate = now.Date;
                    break;

                case "YESTERDAY":
                    startDate = now.Date.AddDays(-1);
                    endDate = now.Date;
                    break;

                case "CURRENT_WEEK":
                    int diff = (7 + (now.Date.DayOfWeek - DayOfWeek.Monday)) % 7;
                    startDate = now.Date.AddDays(-1 * diff);
                    break;

                case "LAST_WEEK":
                    int lastWeekDiff = (7 + (now.Date.DayOfWeek - DayOfWeek.Monday)) % 7;
                    startDate = now.Date.AddDays(-1 * lastWeekDiff).AddDays(-7);
                    endDate = now.Date.AddDays(-1 * lastWeekDiff);
                    break;

                case "CURRENT_MONTH":
                    startDate = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                    break;

                case "LAST_MONTH":
                    var lastMonth = now.AddMonths(-1);
                    startDate = new DateTime(lastMonth.Year, lastMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                    endDate = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                    break;

                case "ALL_TIME":
                default:
                    break;
            }
        }
    }
}
