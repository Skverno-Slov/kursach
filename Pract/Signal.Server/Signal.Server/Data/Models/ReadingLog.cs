using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Signal.Server.Data.Models;

[Table("reading_log")]
[Index("EquipmentId", "WriteDateTime", Name = "idx_metrics_device_time", IsDescending = new[] { false, true })]
public partial class ReadingLog
{
    [Key]
    [Column("reading_log_id")]
    public int ReadingLogId { get; set; }

    [Column("equipment_id")]
    public int EquipmentId { get; set; }

    [Column("status_id")]
    public int StatusId { get; set; }

    [Column("reading_type_id")]
    public int ReadingTypeId { get; set; }

    [Column("write_date_time")]
    public DateTime WriteDateTime { get; set; }

    [Column("value")]
    [StringLength(50)]
    public string Value { get; set; } = null!;

    [ForeignKey("EquipmentId")]
    [InverseProperty("ReadingLogs")]
    public virtual Equipment Equipment { get; set; } = null!;

    [ForeignKey("ReadingTypeId")]
    [InverseProperty("ReadingLogs")]
    public virtual ReadingType ReadingType { get; set; } = null!;

    [ForeignKey("StatusId")]
    [InverseProperty("ReadingLogs")]
    public virtual Status Status { get; set; } = null!;
}
