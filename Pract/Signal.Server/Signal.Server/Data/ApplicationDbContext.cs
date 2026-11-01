using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using Signal.Server.Data.Models;

namespace Signal.Server.Data;

public partial class ApplicationDbContext : DbContext
{
    public ApplicationDbContext()
    {
    }

    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Equipment> Equipment { get; set; }

    public virtual DbSet<ReadingLog> ReadingLogs { get; set; }

    public virtual DbSet<ReadingType> ReadingTypes { get; set; }

    public virtual DbSet<Role> Roles { get; set; }

    public virtual DbSet<Session> Sessions { get; set; }

    public virtual DbSet<Status> Statuses { get; set; }

    public virtual DbSet<User> Users { get; set; }

    public virtual DbSet<ViewLatestEquipmentReading> ViewLatestEquipmentReadings { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        => optionsBuilder.UseNpgsql("Host=localhost;Port=5432;Database=signal_track_db;Username=user1;Password=123");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Equipment>(entity =>
        {
            entity.HasKey(e => e.EquipmentId).HasName("equipment_pkey");

            entity.HasOne(d => d.Status).WithMany(p => p.Equipment)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("equipment_status_id_fkey");
        });

        modelBuilder.Entity<ReadingLog>(entity =>
        {
            entity.HasKey(e => e.ReadingLogId).HasName("reading_log_pkey");

            entity.Property(e => e.WriteDateTime).HasDefaultValueSql("now()");

            entity.HasOne(d => d.Equipment).WithMany(p => p.ReadingLogs).HasConstraintName("reading_log_equipment_id_fkey");

            entity.HasOne(d => d.ReadingType).WithMany(p => p.ReadingLogs)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("reading_log_reading_type_id_fkey");

            entity.HasOne(d => d.Status).WithMany(p => p.ReadingLogs)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("reading_log_status_id_fkey");
        });

        modelBuilder.Entity<ReadingType>(entity =>
        {
            entity.HasKey(e => e.ReadingTypeId).HasName("reading_type_pkey");
        });

        modelBuilder.Entity<Role>(entity =>
        {
            entity.HasKey(e => e.RoleId).HasName("role_pkey");
        });

        modelBuilder.Entity<Session>(entity =>
        {
            entity.HasKey(e => e.SessionId).HasName("session_pkey");

            entity.HasOne(d => d.User).WithMany(p => p.Sessions).HasConstraintName("session_user_id_fkey");
        });

        modelBuilder.Entity<Status>(entity =>
        {
            entity.HasKey(e => e.StatusId).HasName("status_pkey");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.UserId).HasName("user_pkey");

            entity.HasMany(d => d.Roles).WithMany(p => p.Users)
                .UsingEntity<Dictionary<string, object>>(
                    "UserRole",
                    r => r.HasOne<Role>().WithMany()
                        .HasForeignKey("RoleId")
                        .HasConstraintName("user_role_role_id_fkey"),
                    l => l.HasOne<User>().WithMany()
                        .HasForeignKey("UserId")
                        .HasConstraintName("user_role_user_id_fkey"),
                    j =>
                    {
                        j.HasKey("UserId", "RoleId").HasName("user_role_pkey");
                        j.ToTable("user_role");
                        j.IndexerProperty<int>("UserId").HasColumnName("user_id");
                        j.IndexerProperty<int>("RoleId").HasColumnName("role_id");
                    });
        });

        modelBuilder.Entity<ViewLatestEquipmentReading>(entity =>
        {
            entity.ToView("view_latest_equipment_readings");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
