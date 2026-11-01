using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Signal.Server.Controllers
{
    [ApiController]
    [Route("api")]
    public class PingController : ControllerBase
    {
        [AllowAnonymous]
        [HttpGet("ping")]
        public IActionResult Ping()
        {
            return Ok(new { service = "SignalTrack.Api" });
        }
    }
}
