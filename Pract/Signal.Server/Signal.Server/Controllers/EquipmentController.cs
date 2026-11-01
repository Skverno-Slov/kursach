using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Signal.Server.Data.Dtos;
using Signal.Server.Services;
using System.Security.Claims;

namespace SignalTrack.Api.Controllers;

[ApiController]
[Route("api/equipment")] 
public class EquipmentController(EquipmentService equipmentService) : ControllerBase
{
    private readonly EquipmentService equipmentService = equipmentService;

    [Authorize]
    [HttpGet("{serialNumber}/logs")]
    public async Task<IActionResult> GetEquipmentLogs(
    [FromRoute] string serialNumber,
    [FromQuery] string period = "ALL_TIME",
    [FromQuery] string? identifier = null,
    [FromQuery] int page = 1,
    [FromQuery] int pageSize = 30)
    {
        var result = await equipmentService.GetEquipmentLogsAsync(serialNumber, period, identifier, page, pageSize);
        return Ok(result);
    }

    [Authorize]
    [HttpGet("{serialNumber}/graph")]
    public async Task<IActionResult> GetGraphData([FromRoute] string serialNumber, [FromQuery] string period = "ALL_TIME")
    {
        var points = await equipmentService.GetFullGraphDataAsync(serialNumber, period);
        return Ok(points);
    }

    [Authorize]
    [HttpGet]
    public async Task<IActionResult> GetEquipment()
    {
        var devices = await equipmentService.GetEquipmentAsync();
        return Ok(devices);
    }

    [HttpGet("admin-panel")]
    public async Task<IActionResult> GetEquipment([FromQuery] int page, [FromQuery] int pageSize = 10)
    {
        var devices = await equipmentService.GetEquipmentAsync(page, pageSize);
        return Ok(devices);
    }

    [HttpGet("reading-types")]
    public async Task<IActionResult> GetReadingTypes([FromQuery] int page, [FromQuery] int pageSize = 10)
    {
        var readingTypes = await equipmentService.GetReadingTypesAsync(page, pageSize);
        return Ok(readingTypes);
    }

    [HttpPost("logs")]
    public async Task<IActionResult> Create([FromBody] CreateReadingLogDto dto)
    {
        try
        {
            var result = await equipmentService.AddReadingLogAsync(dto);
            return StatusCode(201, result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch
        {
            return BadRequest();
        }
    }

    [Authorize]
    [HttpGet("{serialNumber}/latest")]
    public async Task<ActionResult<IEnumerable<LatestReadingResponse>>> GetLatestReadings(string serialNumber)
    {
        var exists = await equipmentService.CheckEquipmentExistsAsync(serialNumber);
        if (!exists)
        {
            return NotFound($"Прибор с серийным номером '{serialNumber}' не найден.");
        }

        var readings = await equipmentService.GetLatestReadingsAsync(serialNumber);
        return Ok(readings);
    }

    [Authorize(Roles = "Администратор")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteEquipment(int id)
    {
        var result = await equipmentService.DeleteEquipmentAsync(id);
        if (!result) return NotFound(new { message = "Оборудование не найдено" });

        return NoContent();
    }

    [Authorize(Roles = "Администратор")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateEquipment(int id, [FromBody] EquipmentDto dto)
    {
        try
        {
            var result = await equipmentService.UpdateEquipmentAsync(id, dto);
            if (!result) return NotFound(new { message = "Оборудование не найдено" });

            return Ok(new { message = "Данные успешно обновлены" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize(Roles = "Администратор")]
    [HttpDelete("reading-types/{id}")]
    public async Task<IActionResult> DeleteReadingType(int id)
    {
        var result = await equipmentService.DeleteReadingTypeAsync(id);
        if (!result) return NotFound(new { message = "Тип показания не найден" });

        return NoContent();
    }


    [Authorize(Roles = "Администратор")]
    [HttpPut("reading-types/{id}")]
    public async Task<IActionResult> UpdateReadingType(int id, [FromBody] ReadingTypeDto dto)
    {
        try
        {
            var result = await equipmentService.UpdateReadingTypeAsync(id, dto);
            if (!result) return NotFound(new { message = "Тип показания не найден" });

            return Ok(new { message = "Данные успешно обновлены" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
