// ── Password visibility toggle ───────────────────────────────────
(function () {
    var btn = document.getElementById('btnTogglePwd');
    var icon = document.getElementById('eyeIcon');
    var pwdBox = document.getElementById('txtPassword');

    if (!btn || !pwdBox) return;

    btn.addEventListener('click', function (e) {
        e.preventDefault();
        var isHidden = pwdBox.type === 'password';
        pwdBox.type = isHidden ? 'text' : 'password';

        if (isHidden) {
            icon.classList.replace('fa-eye', 'fa-eye-slash');
            btn.setAttribute('aria-label', 'Hide password');
        } else {
            icon.classList.replace('fa-eye-slash', 'fa-eye');
            btn.setAttribute('aria-label', 'Show password');
        }
    });
}());

// ── Client-side validation ────────────────────────────────────────
function validateLoginForm() {
    var userVal = document.getElementById('txtUsername').value.trim();
    var pwdVal = document.getElementById('txtPassword').value;
    var grpUser = document.getElementById('grpUsername');
    var grpPwd = document.getElementById('grpPassword');
    var valid = true;

    // Reset state
    grpUser.classList.remove('has-error');
    grpPwd.classList.remove('has-error');
    hideJsAlert();

    if (!userVal) {
        grpUser.classList.add('has-error');
        valid = false;
    }
    if (!pwdVal) {
        grpPwd.classList.add('has-error');
        valid = false;
    }

    if (!valid) {
        showJsAlert('Please fill in all required fields.');
    }

    return valid;
}

// Clear errors when user starts typing
document.getElementById('txtUsername').addEventListener('input', function () {
    document.getElementById('grpUsername').classList.remove('has-error');
    hideJsAlert();
});
document.getElementById('txtPassword').addEventListener('input', function () {
    document.getElementById('grpPassword').classList.remove('has-error');
    hideJsAlert();
});

// ── Alert helpers ─────────────────────────────────────────────────
function showJsAlert(msg) {
    var alert = document.getElementById('jsAlert');
    document.getElementById('jsAlertMsg').textContent = msg;
    alert.classList.add('is-visible');
    alert.style.animation = 'none';
    void alert.offsetWidth; // reflow
    alert.style.animation = '';
}

function hideJsAlert() {
    document.getElementById('jsAlert').classList.remove('is-visible');
}

// ── Forgot password placeholder ───────────────────────────────────
function showForgotToast() {
    showJsAlert('Password reset is not yet available. Please contact your administrator.');
}

// ── Enter key submits on any field ─────────────────────────────────
document.addEventListener('keydown', function (e) {
    if (e.key === 'Enter') {
        var btn = document.getElementById('btnLogin');
        if (btn) btn.click();
    }
});