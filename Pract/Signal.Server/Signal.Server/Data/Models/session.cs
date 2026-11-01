using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Signal.Server.Data.Models;

[Table("session")]
[Index("UserId", Name = "idx_sessions_user")]
[Index("RefreshToken", Name = "session_refresh_token_key", IsUnique = true)]
public partial class Session
{
    [Key]
    [Column("session_id")]
    public int SessionId { get; set; }

    [Column("user_id")]
    public int UserId { get; set; }

    [Column("refresh_token")]
    public string RefreshToken { get; set; } = null!;

    [Column("device")]
    [StringLength(255)]
    public string? Device { get; set; }

    [Column("session_end_date_time")]
    public DateTime SessionEndDateTime { get; set; }

    [ForeignKey("UserId")]
    [InverseProperty("Sessions")]
    public virtual User User { get; set; } = null!;
}
