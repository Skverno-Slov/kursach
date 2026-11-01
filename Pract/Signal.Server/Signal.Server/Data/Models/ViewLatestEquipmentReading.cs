using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Signal.Server.Data.Models;

[Keyless]
public partial class ViewLatestEquipmentReading
{
    [Column("serial_number")]
    public string? SerialNumber { get; set; } 

    [Column("metric_key")]
    [StringLength(19)]
    public string? MetricKey { get; set; }

    [Column("label")]
    [StringLength(50)]
    public string? Label { get; set; }

    [Column("value")]
    [StringLength(50)]
    public string? Value { get; set; }

    [Column("unit")]
    [StringLength(20)]
    public string? Unit { get; set; }

    [Column("status")]
    [StringLength(50)]
    public string? Status { get; set; }

    [Column("datetime")]
    public DateTime? Datetime { get; set; }

    [Column("min_value")]
    public decimal? MinValue { get; set; }

    [Column("max_value")] 
    public decimal? MaxValue { get; set; }
}
