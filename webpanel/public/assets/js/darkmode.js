function setCookie(cname, cvalue) {
  const d = new Date();
  d.setTime(d.getTime() + (365 * 24 * 60 * 60 * 1000));
  let expires = "expires="+d.toUTCString();
  document.cookie = cname + "=" + cvalue + ";" + expires + ";SameSite=Lax;path=/";
}

function getCookie(cname) {
  let name = cname + "=";
  let ca = document.cookie.split(';');
  for(let i = 0; i < ca.length; i++) {
    let c = ca[i];
    while (c.charAt(0) == ' ') {
      c = c.substring(1);
    }
    if (c.indexOf(name) == 0) {
      return c.substring(name.length, c.length);
    }
  }
  return "";
}

function checkCookie() {
  let darkmode = getCookie("darkmode");
  if (darkmode != "") {
    document.documentElement.setAttribute('data-bs-theme', darkmode === "0" ? 'light' : 'dark');
document.getElementById('btnDarkModeSwitch').checked = darkmode !== "0";
  }
}

checkCookie();

document.getElementById('btnDarkModeSwitch').addEventListener('click',()=>{
    if (document.documentElement.getAttribute('data-bs-theme') == 'dark') {
        document.documentElement.setAttribute('data-bs-theme','light')
        setCookie("darkmode",0);
    }
    else {
        document.documentElement.setAttribute('data-bs-theme','dark')
        setCookie("darkmode",1);
    }
})
