using FluentAssertions;
using Signal.Server.Data.Dtos;
using Signal.Server.Data.Models.Models;
using Signal.Server.Services;

namespace Signal.Test
{
    public class EquipmentServiceTests : DbTestBase
    {
        private readonly EquipmentService equipmentService;

        public EquipmentServiceTests() => equipmentService = new EquipmentService(Context);

        [Fact]
        public async Task GetEquipmentLogsAsync_CorrectParams_ReturnFilteredOutOkStatusLogsResponceWithPagination()
        {
            var equipment = new Equipment
            {
                EquipmentId = 1,
                SerialNumber = "SN123",
                Model = "Model X", 
                Name = "Equip1"    
            };
            var statusOk = new Status { StatusId = 1, Name = "OK" };
            var statusError = new Status { StatusId = 2, Name = "Error" };
            var readingType = new ReadingType { ReadingTypeId = 1, Identifier = "TEMP", Name = "Temperature", Unit = "C" };

            Context.Equipment.Add(equipment);
            Context.Statuses.AddRange(statusOk, statusError);
            Context.ReadingTypes.Add(readingType);

            Context.ReadingLogs.AddRange(
                new ReadingLog { Equipment = equipment, Status = statusOk, ReadingType = readingType, Value = "22", WriteDateTime = DateTime.UtcNow.AddMinutes(-5) },
                new ReadingLog { Equipment = equipment, Status = statusError, ReadingType = readingType, Value = "50", WriteDateTime = DateTime.UtcNow.AddMinutes(-10) },
                new ReadingLog { Equipment = equipment, Status = statusError, ReadingType = readingType, Value = "60", WriteDateTime = DateTime.UtcNow.AddMinutes(-20) }
            );
            await Context.SaveChangesAsync();

            var result = await equipmentService.GetEquipmentLogsAsync(
                serialNumber: "SN123",
                periodType: "HOUR_1",
                readingIdentifier: null,
                page: 1,
                pageSize: 1
            );

            result.Should().NotBeNull();
            result.TotalCount.Should().Be(2);
            result.Logs.Should().HaveCount(1);
            result.Logs[0].ReadingValue.Should().Be("50");
        }

        [Fact]
        public async Task CheckEquipmentExistsAsync_EquipmentExists_ReturnTrue()
        {
            Context.Equipment.Add(new Equipment
            {
                SerialNumber = "ABC",
                Model = "Model Default", 
                Name = "Name Default"    
            });
            await Context.SaveChangesAsync();

            var exists = await equipmentService.CheckEquipmentExistsAsync("ABC");
            var notExists = await equipmentService.CheckEquipmentExistsAsync("XYZ");

            exists.Should().BeTrue();
            notExists.Should().BeFalse();
        }
    }
}
