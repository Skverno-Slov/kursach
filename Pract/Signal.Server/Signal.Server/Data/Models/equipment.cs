using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Signal.Server.Data.Models;

[Table("equipment")]
[Index("SerialNumber", Name = "equipment_serial_number_key", IsUnique = true)]
public partial class Equipment
{
    [Key]
    [Column("equipment_id")]
    public int EquipmentId { get; set; }

    [Column("status_id")]
    public int StatusId { get; set; }

    [Column("serial_number")]
    [StringLength(100)]
    public string SerialNumber { get; set; } = null!;

    [Column("name")]
    [StringLength(150)]
    public string Name { get; set; } = null!;

    [Column("model")]
    [StringLength(100)]
    public string Model { get; set; } = null!;

    [Column("ip_address")]
    [StringLength(39)]
    public string? IpAddress { get; set; }

    [InverseProperty("Equipment")]
    public virtual ICollection<ReadingLog> ReadingLogs { get; set; } = new List<ReadingLog>();

    [ForeignKey("StatusId")]
    [InverseProperty("Equipment")]
    public virtual Status Status { get; set; } = null!;
}
