using System;
using System.Configuration;
using System.Data.SqlClient;

namespace JOCINAPharm.Data
{
    /// <summary>
    /// Centralized database access helper. Single source of truth for the
    /// connection string (read from Web.config &lt;connectionStrings&gt;), so no
    /// page or repository hardcodes credentials. Mirrors the inline ADO.NET
    /// style already used by Login.aspx.cs, but in one reusable place.
    /// </summary>
    public static class Db
    {
        // Connection string name shared by every module (see Web.config).
        public const string ConnectionName = "PharmaDBConnection";

        /// <summary>The raw connection string, or null if not configured.</summary>
        public static string ConnectionString
        {
            get { return ConfigurationManager.ConnectionStrings[ConnectionName]?.ConnectionString; }
        }

        /// <summary>
        /// Creates a new (un-opened) SqlConnection. Callers own its lifetime
        /// and should wrap it in a using block.
        /// </summary>
        public static SqlConnection CreateConnection()
        {
            string cs = ConnectionString;
            if (string.IsNullOrEmpty(cs))
                throw new InvalidOperationException(
                    "Connection string '" + ConnectionName + "' is not configured in Web.config.");

            return new SqlConnection(cs);
        }
    }
}
