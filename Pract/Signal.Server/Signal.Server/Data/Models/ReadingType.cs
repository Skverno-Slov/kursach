using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Signal.Server.Data.Models;

[Table("reading_type")]
[Index("Identifier", Name = "reading_type_identifier_key", IsUnique = true)]
public partial class ReadingType
{
    [Key]
    [Column("reading_type_id")]
    public int ReadingTypeId { get; set; }

    [Column("identifier")]
    [StringLength(19)]
    public string Identifier { get; set; } = null!;

    [Column("name")]
    [StringLength(50)]
    public string Name { get; set; } = null!;

    [Column("unit")]
    [StringLength(20)]
    public string? Unit { get; set; }

    [Column("min_value")]
    [Precision(10, 2)]
    public decimal? MinValue { get; set; }

    [Column("max_value")]
    [Precision(10, 2)]
    public decimal? MaxValue { get; set; }

    [InverseProperty("ReadingType")]
    public virtual ICollection<ReadingLog> ReadingLogs { get; set; } = new List<ReadingLog>();
}
