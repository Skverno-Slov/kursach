using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Signal.Server.Data.Models;

[Table("status")]
[Index("Name", Name = "status_name_key", IsUnique = true)]
public partial class Status
{
    [Key]
    [Column("status_id")]
    public int StatusId { get; set; }

    [Column("name")]
    [StringLength(50)]
    public string Name { get; set; } = null!;

    [InverseProperty("Status")]
    public virtual ICollection<Equipment> Equipment { get; set; } = new List<Equipment>();

    [InverseProperty("Status")]
    public virtual ICollection<ReadingLog> ReadingLogs { get; set; } = new List<ReadingLog>();
}
