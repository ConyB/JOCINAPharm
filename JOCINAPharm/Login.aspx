<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="JOCINAPharm.Login" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <link rel="icon" href="favicon.ico" sizes="any" type="image/x-icon" />
    <title>Sign In &mdash; JOCINAPharm</title>

    <%-- Vendor CSS --%>
    <link rel="stylesheet"
          href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
          crossorigin="anonymous" />
    <link rel="stylesheet"
          href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css"
          crossorigin="anonymous" />

    <%-- Google Fonts — Poppins --%>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap"
          rel="stylesheet" />

    <%-- Application design tokens --%>
    <link href="<%= ResolveUrl("~/css/theme.css") %>" rel="stylesheet" />
    
    <link href="<%= ResolveUrl("~/css/login.css") %>" rel="stylesheet" />
</head>
<body>
<form id="loginForm" runat="server" autocomplete="off">

    <div class="login-shell">

        <%-- ════════════════════════════════════════════════════════
             LEFT DECORATIVE PANEL
             ════════════════════════════════════════════════════════ --%>
        <div class="login-panel">

            <%-- Brand --%>
            <div class="panel-brand">
                <div class="panel-brand-icon">
                    <i class="fa-solid fa-pills"></i>
                </div>
                <div>
                    <div class="panel-brand-name">JOCINAPharm</div>
                    <div class="panel-brand-tag">Pharmacy Management System</div>
                </div>
            </div>

            <%-- Headline + features --%>
            <div class="panel-illustration">
                <h1 class="panel-headline">
                    Manage your pharmacy<br/>
                    <span>smarter, faster.</span>
                </h1>
                <p class="panel-subtext">
                    A complete platform for inventory, billing, prescriptions,
                    and customer management — all in one place.
                </p>

                <div class="panel-features">
                    <div class="panel-feature">
                        <div class="panel-feature-dot"></div>
                        <span class="panel-feature-text">Real-time inventory tracking &amp; expiry alerts</span>
                    </div>
                    <div class="panel-feature">
                        <div class="panel-feature-dot"></div>
                        <span class="panel-feature-text">Role-based access for Admins, Pharmacists &amp; Cashiers</span>
                    </div>
                    <div class="panel-feature">
                        <div class="panel-feature-dot"></div>
                        <span class="panel-feature-text">Sales, billing &amp; prescription management</span>
                    </div>
                    <div class="panel-feature">
                        <div class="panel-feature-dot"></div>
                        <span class="panel-feature-text">Comprehensive reporting &amp; analytics</span>
                    </div>
                </div>
            </div>

            <%-- Footer --%>
            <p class="panel-footer-text">&copy; 2026 JOCINAPharm &mdash; All rights reserved.</p>
        </div>

        <%-- ════════════════════════════════════════════════════════
             RIGHT FORM COLUMN
             ════════════════════════════════════════════════════════ --%>
        <div class="login-form-col">
            <div class="login-form-inner">

                <h2 class="login-title">Welcome back</h2>
                <p class="login-subtitle">Sign in to your account to continue.</p>

                <%-- ── Server-side error (shown from code-behind) ── --%>
                <asp:Label ID="lblError" runat="server"
                           CssClass="server-error-label"
                           Visible="false" />

                <%-- ── Client-side alert (shown by JS) ── --%>
                <div id="jsAlert" class="lf-alert" role="alert" aria-live="polite">
                    <i class="fa-solid fa-circle-exclamation"></i>
                    <span id="jsAlertMsg"></span>
                </div>

                <%-- ── Username ── --%>
                <div class="lf-group" id="grpUsername">
                    <label class="lf-label" for="<%= txtUsername.ClientID %>">Username</label>
                    <div class="lf-input-wrap">
                        <asp:TextBox ID="txtUsername"
                                     runat="server"
                                     CssClass="lf-input"
                                     placeholder="Enter your username"
                                     MaxLength="100"
                                     autocomplete="username" />
                        <i class="fa-regular fa-user lf-input-icon"></i>
                    </div>
                    <span class="lf-invalid-msg">Please enter your username.</span>
                </div>

                <%-- ── Password ── --%>
                <div class="lf-group" id="grpPassword">
                    <label class="lf-label" for="<%= txtPassword.ClientID %>">Password</label>
                    <div class="lf-input-wrap">
                        <asp:TextBox ID="txtPassword"
                                     runat="server"
                                     CssClass="lf-input"
                                     TextMode="Password"
                                     placeholder="Enter your password"
                                     MaxLength="128"
                                     autocomplete="current-password" />
                        <i class="fa-solid fa-lock lf-input-icon"></i>
                        <button type="button" class="lf-eye-btn" id="btnTogglePwd"
                                aria-label="Show password" title="Show / hide password">
                            <i class="fa-regular fa-eye" id="eyeIcon"></i>
                        </button>
                    </div>
                    <span class="lf-invalid-msg">Please enter your password.</span>
                </div>

                <%-- ── Remember me / Forgot ── --%>
                <div class="lf-options">
                    <label class="lf-remember">
                        <input type="checkbox" id="chkRemember" />
                        Remember me
                    </label>
                    <button type="button" class="lf-forgot" onclick="showForgotToast()">
                        Forgot password?
                    </button>
                </div>

                <%-- ── Login button ── --%>
                <asp:Button ID="btnLogin"
                            runat="server"
                            Text="Sign In"
                            CssClass="lf-btn-login"
                            OnClick="btnLogin_Click"
                            OnClientClick="return validateLoginForm();" />

                <div class="lf-divider"></div>

                <div class="lf-footer">
                    Secure login &mdash; your session is protected.<br />
                    &copy; 2026 JOCINAPharm. All rights reserved.
                </div>

            </div>
        </div><%-- /login-form-col --%>

    </div><%-- /login-shell --%>

</form>

<%-- Vendor JS --%>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"
        crossorigin="anonymous"></script>

<script src="<%= ResolveUrl("~/js/login.js") %>"></script>

</body>
</html>
