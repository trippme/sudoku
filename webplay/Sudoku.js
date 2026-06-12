var e = true
  , g = false;
function k() {
    return function() {}
}
var l = {};
l.page = -1;
l.sb = -1;
l.i = -1;
l.tb = -1;
l.o = 0;
l.height = 1;
l.width = 1;
l.Zb = g;
l.ya = function(a, b) {
    if (l.page == 2) {
        l.sb = a;
        l.Uc = parseInt(b);
        l.Tc = b
    } else
        l.oc(a, b)
}
;
l.oc = function(a, b) {
    l.sb = l.page;
    l.Uc = l.height;
    l.Tc = l.button;
    l.Sa();
    l.page = a;
    switch (a) {
    case 0:
        l.height = parseInt(b);
        l.width = 1;
        if (l.i >= 0) {
            l.i = 0;
            l.o = 0
        }
        break;
    case 1:
        l.height = 9;
        l.width = 2;
        break;
    case 2:
        l.height = parseInt(b);
        l.width = 1;
        break;
    case 3:
        l.height = 1;
        l.width = 2;
        break;
    case 4:
        l.height = 9;
        l.width = 12;
        break;
    case 5:
        l.height = 3;
        l.width = 1;
        break;
    case 6:
        l.height = l.width = 1;
        l.button = b
    }
    l.i >= 0 && l.Bc();
    l.tb = -1;
    l.kb()
}
;
l.Hd = function() {
    l.oc(l.sb, l.sb == 6 ? l.Tc : l.Uc)
}
;
l.tc = function() {
    if (!l.Zb) {
        l.Sa();
        l.i = -1
    }
}
;
l.kb = function() {
    var a = 0;
    if (l.i >= 0) {
        switch (l.page) {
        case 0:
        case 1:
        case 2:
        case 3:
        case 5:
        case 6:
            a = l.Ia(l.i, l.o);
            break;
        case 4:
            if (l.o < 9)
                n.kc(o.Xa(l.i, l.o));
            else
                a = l.Ia(l.i, l.o)
        }
        if (a)
            a.className += " focus"
    }
}
;
l.Sa = function() {
    var a = 0, b;
    if (l.i >= 0) {
        switch (l.page) {
        case 0:
        case 1:
        case 2:
        case 3:
        case 5:
        case 6:
            a = l.Ia(l.i, l.o);
            break;
        case 4:
            if (l.o < 9)
                n.kc(-1);
            else
                a = l.Ia(l.i, l.o)
        }
        if (a) {
            b = a.className.indexOf(" focus");
            if (b > 0)
                a.className = a.className.substring(0, b)
        }
    }
}
;
l.Bc = function() {
    switch (l.page) {
    case 0:
    case 3:
    case 6:
        l.i = l.o = 0;
        break;
    case 1:
        if (p.U >= -6) {
            l.i = p.U + 6;
            if (l.i > 8) {
                l.i -= 8;
                l.o = 1
            } else
                l.o = 0
        }
        break;
    case 2:
    case 5:
        l.i = l.height - 1;
        l.o = 0;
        break;
    case 4:
        if (s.m >= 0 && s.m < 81) {
            l.i = o.Tb(s.m);
            l.o = o.Sb(s.m)
        } else
            l.i = l.o = 0
    }
}
;
l.Ia = function(a, b) {
    switch (l.page) {
    case 0:
        return w[a];
    case 1:
        return b == 0 ? a < 7 ? w[a] : w[14] : w[7 + a];
    case 2:
        return A[l.height - a - 1];
    case 3:
        return document.getElementById(b ? "FeedCancel" : "FeedSend");
    case 4:
        if (b >= 9)
            switch (a) {
            case 0:
            case 1:
                return D[b - 9];
            case 2:
                return D[3 + b - 9];
            case 3:
            case 4:
                return D[6 + b - 9];
            case 5:
                return b == 11 ? D[12] : D[10];
            case 6:
                return b == 11 ? D[13] : D[9];
            case 7:
            case 8:
                if (b == 11)
                    return D[14];
                return D[11]
            }
        break;
    case 5:
        if (a >= 0 && a <= 2)
            return D[15 + a];
        break;
    case 6:
        return l.button
    }
    return 0
}
;
l.hb = function(a) {
    var b, d, f, h, j;
    if (l.i < 0)
        if (l.tb >= 0)
            l.i = l.tb;
        else
            l.Bc();
    else {
        j = 0;
        b = l.i;
        d = l.o;
        do {
            switch (a) {
            case 0:
                if (b)
                    --b;
                else
                    b = l.height - 1;
                break;
            case 1:
                if (b < l.height - 1)
                    ++b;
                else
                    b = 0;
                break;
            case 2:
                if (d > 0)
                    --d;
                else
                    d = l.width - 1;
                break;
            case 3:
                if (d < l.width - 1)
                    ++d;
                else
                    d = 0
            }
            f = g;
            if (l.page == 4)
                if (a == 0 || a == 1) {
                    if (b >= 5 && d == 10)
                        d = 9;
                    if (d >= 9 && (b == 0 || b == 4 || b == 8))
                        f = e
                } else if (d >= 9) {
                    if (b == 0)
                        ++b;
                    else if (b == 4 || b == 8)
                        --b;
                    if (b >= 5 && d == 10)
                        f = e
                }
            if (!f)
                if ((h = l.Ia(b, d)) && h.className.indexOf(" gray") > 0)
                    f = e;
            j >= 9 && alert("ArrowKeys.Move looping!")
        } while (f && ++j < 10);
        l.Sa();
        l.i = b;
        l.o = d
    }
    l.kb();
    l.tb = l.i;
    return e
}
;
l.Jd = function() {
    var a;
    if (l.i >= 0)
        if (l.page == 4 && l.o < 9) {
            s.ec(o.Xa(l.i, l.o));
            l.Sa();
            l.i = 2;
            l.o = 10;
            l.kb();
            n.K();
            return e
        } else if (a = l.Ia(l.i, l.o))
            if (a = a.getAttribute("enjoysudoku:action")) {
                l.Sa();
                l.Zb = e;
                eval(a);
                l.Zb = g;
                if (l.page == 4 && l.o >= 9 && l.i < 5 && s.m >= 0 && s.m < 81) {
                    l.i = o.Tb(s.m);
                    l.o = o.Sb(s.m)
                }
                l.kb();
                n.K();
                return e
            }
    return g
}
;
l.fd = function(a) {
    var b;
    if (l.page == 4) {
        b = l.i >= 0 && l.o < 9 ? o.Xa(l.i, l.o) : -1;
        s.zd(a ? a : 10, b);
        return e
    }
    return g
}
;
l.xd = function() {
    return l.page == 4
}
;
var E, F = [["1", "2", "3", "4", "5", "6", "7", "8", "9"], ["A", "B", "C", "D", "E", "F", "G", "H", "I"], ["\u4e00", "\u4e8c", "\u4e09", "\u56db", "\u4e94", "\u516d", "\u4e03", "\u516b", "\u4e5d"], ["\u58f9", "\u8d30", "\u53c1", "\u8086", "\u4f0d", "\u9646", "\u67d2", "\u634c", "\u7396"], ["\u58f9", "\u8cb3", "\u53c4", "\u8086", "\u4f0d", "\u9678", "\u67d2", "\u634c", "\u7396"]], aa = [["#FFFFFF", "#ABB5C9", "#99DADF", "#333333", "#C91002", "#FFFFFF", "#EEB5F3"], ["#EEEEEE", "#8B96AA", "#04B6C4", "#555555", "#FF660A", "#EEEEEE", "#F0F0C6"], ["#000000", "#303540", "#4D2400", "#FFFFFF", "#000000", "#0000DD", "#1A19A5"], ["#0000FF", "#F7F8FB", "#471CE5", "#F7F719", "#FEFEFE", "#000000", "#80054A"], ["#DD0000", "#DB4040", "#DD0000", "#944BDF", "#FFFF00", "#DD0000", "#0000E5"], ["#FFFF66", "#9C36C2", "#F5F0D7", "#EB5E00", "#723EDC", "#FFFF66", "#CC7929"], ["#F9C7C7", "#8282D9", "#D94C4C", "#B30000", "#D9B382", "#F9C7C7", "#9999FF"], ["#66EE66", "#3FA668", "#1AA60A", "#0E8C0E", "#12B312", "#66EE66", "#15D48E"], ["#D4D4FF", "#EAAFDD", "#737070", "#3D3DCC", "#81817D", "#D4D4FF", "#F0E430"]], ba = [["yellow", "violet", "ivory", "orange", "purple", "yellow", "brown"], ["pink", "blue", "red", "red", "tan", "pink", "blue"], ["green", "green", "green", "green", "green", "green", "green"], ["blue", "pink", "gray", "blue", "gray", "blue", "yellow"]];
window.BP = function(a) {
    l.tc();
    s.ec(a);
    n.K()
}
;
var n = {};
n.Oa = 0;
n.Ma = 0;
n.La = 9;
n.Na = 9;
n.f = function(a) {
    var b;
    if (a < 0 || a >= 81) {
        n.Oa = 0;
        n.Ma = 0;
        n.La = 9;
        n.Na = 9
    } else {
        b = o.Tb(a);
        a = o.Sb(a);
        if (b < n.Oa)
            n.Oa = b;
        if (b >= n.La)
            n.La = b + 1;
        if (a < n.Ma)
            n.Ma = a;
        if (a >= n.Na)
            n.Na = a + 1
    }
}
;
n.be = k();
n.A = function(a, b) {
    var d;
    a = D[a];
    switch (b) {
    default:
    case 0:
        b = "white";
        break;
    case 1:
        b = "green";
        break;
    case 2:
        b = "yellow";
        break;
    case 3:
        b = "gray"
    }
    d = a.className;
    a.className = d.substring(0, d.lastIndexOf(" ") + 1) + b
}
;
n.Wd = function(a, b) {
    D[a].innerHTML = "<span></span>" + b
}
;
n.Od = function(a) {
    document.getElementById("time").innerHTML = a.a
}
;
n.Kc = function(a) {
    document.getElementById("difficulty").innerHTML = a
}
;
n.Lc = function(a) {
    ca = a;
    document.getElementById("HintsPane").style.left = a ? H + 487 + "px" : "-4000px";
    document.getElementById("HintsPane").style.top = da + 35 + "px";
    l.ya(a ? 5 : 4)
}
;
n.Qb = function(a) {
    a || n.A(13, 3)
}
;
n.Md = function(a) {
    document.getElementById("Hints").innerHTML = a
}
;
n.K = function() {
    n.Oa < n.La && n.Ma < n.Na && n.od()
}
;
n.Qc = function() {
    var a;
    switch (I.Aa) {
    default:
    case 0:
    case 1:
        a = 0;
        break;
    case 2:
        a = 2;
        break;
    case 3:
        a = 3
    }
    return a
}
;
n.kc = function(a) {
    E >= 0 && n.f(E);
    E = a;
    E >= 0 && n.f(E)
}
;
var L = Array(9);
n.od = function() {
    var a, b, d, f, h, j, q, m, u, x, z, r, t, v, C, y, G, O, K;
    scale = 1.5;
    h = I.ia || s.Ya ? 1 << s.g - 1 : 0;
    switch (I.Aa) {
    default:
    case 0:
        j = 0;
        C = x = Math.round(34 * scale) + "px";
        u = navigator.userAgent.indexOf("Opera") >= 0 ? "&nbsp;" : "&#8199;";
        break;
    case 1:
        j = 0;
        C = x = Math.round(34 * scale) + "px";
        u = navigator.userAgent.indexOf("Opera") >= 0 ? "&nbsp;" : "&#8199;";
        break;
    case 2:
        j = 2;
        C = x = Math.round(30 * scale) + "px";
        u = "&#12288;";
        break;
    case 3:
        j = 3;
        C = x = Math.round(30 * scale) + "px";
        u = "&#12288;"
    }
    if (I.Da == 0) {
        y = z = (j != 0 ? Math.round(16 * scale) : Math.round(22 * scale)) + "px";
        G = r = (j != 0 ? Math.round(10 * scale) : Math.round(15 * scale)) + "px";
        O = t = (j != 0 ? Math.round(12 * scale) : Math.round(16 * scale)) + "px"
    }
    v = (j != 0 ? Math.round(9 * scale) : Math.round(11 * scale)) + "px";
    K = (j != 0 ? Math.round(10 * scale) : Math.round(10 * scale)) + "px";
    for (a = n.Oa; a < n.La; ++a)
        for (b = n.Ma; b < n.Na; ++b) {
            d = o.Xa(a, b);
            if (d == E)
                f = "#F9A91C";
            else {
                f = 0;
                if (s.ma >= 0)
                    f = s.p[s.ma][o.Xa(a, b)];
                else if (d == s.m && s.j == 2)
                    f = 8;
                else if (s.j != 0)
                    if (h == 1 << o.Td)
                        if (M.Ta(d))
                            M.pc(d) || (f = 7);
                        else {
                            if (M.Jb(d) != M.bb(d))
                                f = 7
                        }
                    else if (M.Ta(d)) {
                        if (M.cb(d) == h)
                            f = 6
                    } else if ((M.Jb(d) & h) != 0)
                        f = 7;
                if (!f) {
                    f = o.Sd(d);
                    f = (f & 1) != 0 ? 2 : 1
                }
                f = aa[f - 1][I.ba]
            }
            N[d].style.backgroundColor = f;
            f = M.Ta(d) && M.pc(d) ? aa[3][I.ba] : M.Ta(d) && M.yd(d) ? aa[4][I.ba] : aa[2][I.ba];
            N[d].style.color = f;
            if (M.Ta(d)) {
                N[d].style.fontSize = x;
                N[d].style.lineHeight = C;
                N[d].style.fontWeight = I.Aa == 1 ? "bold" : "normal";
                N[d].innerHTML = F[j][M.ud(d)]
            } else {
                f = M.Jb(d);
                N[d].style.fontWeight = "normal";
                switch (I.Da == 0 && (o.Pc(f) >= 7 || s.vb) ? 1 : I.Da) {
                case 0:
                    m = 0;
                    for (tmask = f; tmask != 0; tmask ^= q) {
                        q = o.Ud(tmask);
                        L[m++] = o.Vd(q)
                    }
                    switch (o.Pc(f)) {
                    default:
                    case 0:
                        N[d].innerHTML = "&nbsp;";
                        break;
                    case 1:
                        N[d].style.fontSize = z;
                        N[d].style.lineHeight = y;
                        N[d].style.letterSpacing = "1px";
                        N[d].innerHTML = "&#8203;" + F[j][L[0]];
                        break;
                    case 2:
                        N[d].style.fontSize = z;
                        N[d].style.lineHeight = y;
                        N[d].style.letterSpacing = "1px";
                        N[d].innerHTML = "&#8203;" + F[j][L[0]] + F[j][L[1]];
                        break;
                    case 3:
                        N[d].style.fontSize = r;
                        N[d].style.lineHeight = G;
                        N[d].style.letterSpacing = "1px";
                        N[d].innerHTML = "&#8203;" + F[j][L[0]] + F[j][L[1]] + F[j][L[2]];
                        break;
                    case 4:
                        N[d].style.fontSize = t;
                        N[d].style.lineHeight = O;
                        N[d].style.letterSpacing = "1px";
                        N[d].innerHTML = "&#8203;" + F[j][L[0]] + F[j][L[1]] + "<br>&#8203;" + F[j][L[2]] + F[j][L[3]];
                        break;
                    case 5:
                    case 6:
                        N[d].style.fontSize = r;
                        N[d].style.lineHeight = G;
                        N[d].style.letterSpacing = "1px";
                        N[d].innerHTML = "&#8203;" + F[j][L[0]] + F[j][L[1]] + F[j][L[2]] + "<br>&#8203;" + F[j][L[3]] + F[j][L[4]] + (m > 5 ? F[j][L[5]] : u)
                    }
                    break;
                case 1:
                    N[d].style.fontSize = v;
                    N[d].style.lineHeight = K;
                    N[d].style.letterSpacing = j != 0 ? "1px" : "5px";
                    N[d].innerHTML = "&#8203;" + (f & 1 ? F[j][0] : u) + (f & 2 ? F[j][1] : u) + (f & 4 ? F[j][2] : u) + "<br>&#8203;" + (f & 8 ? F[j][3] : u) + (f & 16 ? F[j][4] : u) + (f & 32 ? F[j][5] : u) + "<br>&#8203;" + (f & 64 ? F[j][6] : u) + (f & 128 ? F[j][7] : u) + (f & 256 ? F[j][8] : u);
                    break;
                case 2:
                    N[d].style.fontSize = "18px";
                    N[d].style.lineHeight = "16px";
                    N[d].style.letterSpacing = "3px";
                    q = navigator.userAgent.indexOf("Opera") >= 0 ? "&nbsp;" : "&#8194;";
                    N[d].innerHTML = "&#8203;" + (f & 1 ? "&#9632;" : q) + (f & 2 ? "&#9632;" : q) + (f & 4 ? "&#9632;" : q) + "<br>&#8203;" + (f & 8 ? "&#9632;" : q) + (f & 16 ? "&#9632;" : q) + (f & 32 ? "&#9632;" : q) + "<br>&#8203;" + (f & 64 ? "&#9632;" : q) + (f & 128 ? "&#9632;" : q) + (f & 256 ? "&#9632;" : q);
                    break;
                case 3:
                    N[d].style.fontSize = "24px";
                    N[d].style.lineHeight = "16px";
                    N[d].style.letterSpacing = "5px";
                    q = "&nbsp;";
                    N[d].innerHTML = "&#8203;" + (f & 1 ? "\u2022" : q) + (f & 2 ? "\u2022" : q) + (f & 4 ? "\u2022" : q) + "<br>&#8203;" + (f & 8 ? "\u2022" : q) + (f & 16 ? "\u2022" : q) + (f & 32 ? "\u2022" : q) + "<br>&#8203;" + (f & 64 ? "\u2022" : q) + (f & 128 ? "\u2022" : q) + (f & 256 ? "\u2022" : q)
                }
            }
        }
    n.Oa = n.Ma = 9;
    n.La = n.Na = 0
}
;
n.Qd = function(a) {
    var b, d, f;
    f = n.Qc();
    for (b = 0; b < a.length; ) {
        b = a.indexOf("#", b);
        if (b >= 0 && b < a.length - 1 && (d = a.charAt(b + 1)) >= "1" && d <= "9")
            a = a.substr(0, b) + F[f][d - "1"] + a.substr(b + 2);
        else if (b < 0)
            b = a.length;
        else
            ++b
    }
    return a
}
;
var p = {};
p.W = ["1st Lesson", "2nd Lesson", "3rd Lesson", "Easiest", "Easy as Pie", "Picnic", "Simple", "Easy", "Moderate", "Intricate", "Difficult", "Annoying", "Devious", "Fiendish", "Diabolical", "Nightmare", "Legendary", "Impossible", "User Game", "Example", "Practice", "Tutorial"];
p.de = 4;
p.U = -7;
p.Vc = 0;
p.z = Array(18);
p.H = Array(18);
for (i = 0; i < 18; ++i)
    p.H[i] = {};
p.Ea = Array(18);
p.n = Array(5);
for (i = 0; i < 5; ++i)
    p.n[i] = Array(182);
p.O = [0, 0, 0, 0, 0];
p.Gb = function() {
    var a;
    for (a = 0; a < 18; ++a) {
        p.z[a] = 0;
        p.H[a].a = ""
    }
    M.Gb();
    P.xc()
}
;
p.Nd = function(a, b) {
    var d = {};
    d.a = "";
    var f;
    f = 0;
    if (M.Y[0] > 0) {
        M.Ua(M.Y, 0, 182);
        M.Y[0] = 0
    }
    switch (a) {
    case 0:
        b[0] = "Play Game";
        f = 1;
        if (M.h) {
            d.a = typeof p.W[p.d + 6] == "string" ? p.W[p.d + 6] : p.W[p.d + 6].a;
            d.a += " in Progress";
            b[f++] = d.a
        }
        b[f++] = "Learn";
        b[f++] = "Statistics";
        b[f++] = "Settings";
        b[f++] = "Feedback";
        break;
    case 1:
        b[0] = "Today's Game";
        f = 1;
        if (p.n[0][0] > 0)
            b[f++] = "Saved Game";
        break;
    case 2:
        b[0] = 0;
        b[1] = "See Example";
        f = 2;
        break;
    case 3:
        b[0] = 0;
        b[1] = "Play Practice Game";
        f = 2;
        break;
    case 4:
    case 5:
        for (f = 0; f < 14; ++f)
            b[f] = p.W[f] + (a == 4 && p.uc(f - 6) ? " *" : "");
        break;
    case 7:
        b[0] = "Manual";
        b[1] = "Tutorial";
        b[2] = "Sudopedia";
        f = 3;
        break;
    case 8:
        b[0] = "";
        b[1] = "View Tutorial";
        f = 2;
        break;
    case 9:
        b[0] = "";
        b[1] = "View Sudopedia";
        f = 2
    }
    return f
}
;
p.Gd = function(a, b) {
    s.M = 0;
    s.sa = 0;
    switch (a) {
    case 0:
        if (!M.h && b >= 1)
            b += 1;
        b >= 2 && ++b;
        b >= 3 && ++b;
        switch (b) {
        case 0:
            if (M.h)
                Q.Ib(3, "Puzzle in Progress", "You have a puzzle in progress. Would you like to throw it away and start a new puzzle?");
            else
                p.n[0][0] <= 0 ? Q.L(4) : Q.L(1);
            break;
        case 1:
            if (M.h) {
                s.M = 0;
                Q.oa()
            }
            break;
        case 2:
            p.q = 2;
            p.d = p.U;
            s.M = 0;
            p.Rb();
            break;
        case 3:
            Q.gb(1);
            break;
        case 4:
            Q.Va();
            Q.gb(0);
            break;
        case 5:
            Q.gb(2);
            break;
        case 6:
            Q.wd();
            break;
        case 7:
            Q.vd()
        }
        break;
    case 1:
        if (b >= 1)
            b += 2;
        p.n[0][0] <= 0 && b >= 3 && ++b;
        switch (b) {
        case 0:
            Q.L(4);
            break;
        case 1:
            Q.L(5);
            break;
        case 2:
            M.Ja("");
            p.q = 5;
            p.d = 12;
            s.M = 0;
            Q.oa();
            break;
        case 3:
            if (p.n[0][0] > 0) {
                M.sc(p.n[0], 0, 182);
                I.Za || (p.n[0][0] = 0);
                Q.oa()
            } else
                Q.Lb();
            break;
        default:
            Q.Lb()
        }
        break;
    case 4:
        if (b >= 0 && b < 14) {
            p.q = 1;
            p.d = b - 6;
            s.M = 0;
            p.Rb()
        } else
            Q.Lb();
        break;
    case 5:
        if (b >= 0 && b < 14) {
            p.q = 2;
            p.d = b - 6;
            s.M = 0;
            p.Rb()
        } else
            Q.Va()
    }
}
;
p.Rb = function() {
    var a = {};
    a.a = "";
    var b = 0, d, f;
    Q.ab();
    d = 1;
    s.Ya = 0;
    if (p.q == 1) {
        f = Q.za();
        if (p.z[p.d + 6] >= f && p.z[p.d + 6] <= f + 7 && p.H[p.d + 6].a.length > 0) {
            b = Q.Rd();
            a.a = "You have already played today's ";
            a.a += typeof p.W[p.d + 6] == "string" ? p.W[p.d + 6] : p.W[p.d + 6].a;
            a.a += " puzzle of the day. Would you like to play it again?\n(New puzzle available in about ";
            a.a += b.toString();
            a.a += " hour";
            if (b > 1)
                a.a += "s";
            a.a += ".)";
            Q.Ib(2, "Play Again", a.a);
            return
        }
    }
    switch (p.d < 0 ? 10 : p.q) {
    default:
    case 1:
        if (p.U != p.d) {
            p.U = p.d;
            Q.B()
        }
        a.a = "http://www.enjoysudoku.com/puzzles/V3";
        a.a += String.fromCharCode("A".charCodeAt(0) + p.d);
        a.a += Q.za().toString();
        a.a += ".txt";
        d = 2;
        break;
    case 10:
        if (p.U != p.d) {
            p.U = p.d;
            Q.B()
        }
        p.fb();
        return;
    case 2:
        if (p.U != p.d) {
            p.U = p.d;
            Q.B()
        }
        a.a = "http://www.enjoysudoku.com/cgi/q?game=";
        a.a += String.fromCharCode("A".charCodeAt(0) + p.d);
        b = "confirm=1";
        break;
    case 3:
        if (p.U != p.d) {
            p.U = p.d;
            Q.B()
        }
        p.fb();
        return;
    case 5:
        M.Ja("");
        p.d = 12;
        Q.oa();
        return
    }
    Q.lb(d, a.a, b);
    Q.Dc(12)
}
;
p.ic = function() {
    P.Ed(p.d, M.J, M.N > 0, M.T);
    M.h = M.s = 0;
    p.q = 0
}
;
p.uc = function(a) {
    return p.z[a + 6] >= Q.za() && p.z[a + 6] <= Q.za() + 7 && p.H[a + 6].a.length == 82
}
;
p.ae = function(a) {
    return p.Ea[a + 6]
}
;
p.Kd = function(a, b) {
    var d, f, h;
    h = 0;
    if (a.a.charAt(0) == "V" && a.a.length > 1) {
        d = a.a.charAt(1).charCodeAt(0) - 48 - 7;
        if (d >= -6 && d <= -1 && p.H[d + 6].a.length > 1 && b.a.substring(0) == p.H[d + 6].a.substring(1)) {
            h = p.Ea[d + 6];
            p.Ea[d + 6] = -1
        }
    } else {
        d = a.a.charAt(0).charCodeAt(0) - "A".charCodeAt(0);
        if (d >= 0 && d < 12 && a.a.length > 1) {
            f = parseInt(a.a.substring(1));
            if (f == p.z[d + 6] || f == 0 && b.a.substring(0) == p.H[d + 6].a.substring(1)) {
                h = p.Ea[d + 6];
                p.Ea[d + 6] = -1
            }
        }
    }
    return h
}
;
p.Ga = k();
p.fb = function() {
    var a = {};
    a.a = "";
    if (p.d < 0) {
        R.sd(p.d + 6, a);
        M.Ja(a.a);
        M.e.a = "V";
        M.e.a += (p.d + 7).toString();
        if (p.d == -6)
            s.ka("T'Sudoku has one rule:<br>Each digit, from #1 through #9, must appear in every row, every column, and each of the 3x3 blocks.'MT[To complete the puzzle, find the empty cell and figure out which digit goes into it.]");
        else if (p.d == -5)
            s.ka("l000T'<A href=\"http://sudopedia.enjoysudoku.com/Full_House.html\">Full House</A>: a row, column, or block (called a house) that has all but one cell filled in. The remaining cell must contain the remaining digit.'MT[Here, each empty cell belongs to a row or column that already has eight digits in it. Fill the cell in with the digit that does not already appear.]");
        else
            p.d == -4 && s.ka("l001T'<A href=\"http://sudopedia.enjoysudoku.com/Hidden_Single.html\">Hidden Single</A> (block): a block that has only one cell that can still contain the chosen digit.'MT[Here, there is only one cell in the empty block that can contain each digit. Exisiting digits in other blocks rule out all of the other cells.]");
        if (p.q == 1) {
            p.z[p.d + 6] = Q.za();
            p.H[6 + p.d].a = "G";
            p.H[6 + p.d].a += typeof a == "string" ? a : a.a;
            p.Ea[p.d + 6] = 0
        }
        Q.oa()
    } else
        Q.db("Unable to contact the game server!")
}
;
p.Bb = function(a, b) {
    switch (a) {
    case 2:
        if (b == 0) {
            M.Ja(p.H[p.d + 6].a.substring(1));
            M.T = 0;
            if (p.d < 0) {
                M.e.a = "V";
                M.e.a += (p.d + 7).toString()
            } else if (p.H[p.d + 6].a.charAt(0) == "G") {
                M.e.a = "";
                M.e.a += String.fromCharCode("A".charCodeAt(0) + p.d);
                M.e.a += "0"
            } else {
                M.e.a = "";
                M.e.a += String.fromCharCode("A".charCodeAt(0) + p.d);
                M.e.a += p.z[p.d + 6].toString()
            }
            Q.oa()
        } else if (b == 2) {
            kindOfGame = 0;
            Q.Va();
            Q.gb(1)
        } else {
            p.q = 0;
            Q.Va()
        }
        break;
    case 3:
    case 4:
        if (b == 0) {
            p.ic();
            if (a == 4)
                Q.L(3);
            else
                p.n[0][0] <= 0 ? Q.L(4) : Q.L(1)
        } else
            a == 4 && Q.Va()
    }
}
;
p.Wc = function() {
    var a;
    a = M.e.a.charAt(0);
    if (a == "U") {
        p.q = 6;
        p.d = 12
    } else if (a == "V") {
        p.q = 10;
        p.d = M.e.a.charAt(1).charCodeAt(0) - 48 - 7
    } else if (a == "W") {
        p.q = 5;
        p.d = 12
    } else if (a == "X") {
        p.q = 9;
        p.d = 15
    } else if (a == "Y") {
        p.q = 7;
        p.d = 13
    } else if (a == "Z") {
        p.q = 8;
        p.d = 14
    } else if (a >= "A" && a < String.fromCharCode("A".charCodeAt(0) + 12)) {
        p.q = parseInt(M.e.a.substring(1)) > 0 ? 2 : 3;
        p.d = a.charCodeAt(0) - "A".charCodeAt(0)
    } else {
        p.q = 5;
        p.d = 12
    }
}
;
var w, ea, fa, N, D, A, ga, ha, ia, ja, ka, S, ca, la = 0, T = 0, ma = 0, na = 0, oa = 0, H, da, pa, U, W, qa, X, Y, Z;
window.DoLoaded = function() {
    var a;
    if (navigator.userAgent.indexOf("GoogleTV") >= 0 && window.innerWidth != 1280)
        document.getElementsByTagName("body")[0].style.zoom = screen.width > 1280 ? 1.5 : 1;
    qa = X = 0;
    window.onresize();
    ga = 0;
    S = -1;
    ca = g;
    w = Array(18);
    fa = Array(17);
    for (a = 0; a < 18; ++a)
        w[a] = document.getElementById("M" + a);
    N = Array(81);
    for (a = 0; a < 81; ++a)
        N[a] = document.getElementById("G" + a);
    D = Array(18);
    for (a = 0; a < 11; ++a)
        D[a] = document.getElementById("D" + a);
    D[11] = document.getElementById("Hint");
    D[12] = document.getElementById("Undo");
    D[13] = document.getElementById("Redo");
    D[14] = document.getElementById("Game");
    D[15] = document.getElementById("Back");
    D[16] = document.getElementById("More");
    D[17] = document.getElementById("Done");
    n.Qb(g);
    A = Array(9);
    for (a = 0; a < 9; ++a)
        A[a] = document.getElementById("A" + a);
    for (a = 0; a < 5; ++a)
        p.n[a][0] = 0;
    S = -1;
    p.Gb();
    P.xc();
    Q.Ad();
    Q.Cd();
    Q.L(0);
    M.h && Q.oa()
}
;
window.onbeforeunload = function() {
    Q.zc()
}
;
function ra(a, b, d) {
    var f;
    if (d) {
        f = new Date;
        f.setTime(f.getTime() + d * 24 * 60 * 60 * 1E3);
        d = "; expires=" + f.toGMTString()
    } else
        d = "";
    document.cookie = a + "=" + b + d + "; path=/"
}
function sa(a) {
    var b, d;
    a = a + "=";
    b = document.cookie.split(";");
    for (d = 0; d < b.length; ++d) {
        for (c = b[d]; c.charAt(0) == " "; )
            c = c.substring(1, c.length);
        if (c.indexOf(a) == 0)
            return c.substring(a.length, c.length)
    }
    return null
}
window.SetDown = function(a, b) {
    b && l.tc();
    if (b || a == ga) {
        a.className += " down";
        ga = a
    }
}
;
window.SetUp = function(a, b) {
    var d;
    d = a.className.indexOf(" down");
    if (d > 0)
        a.className = a.className.substring(0, d);
    if (b)
        ga = 0
}
;
window.MenuButton = function(a) {
    fa[a] || p.Gd(ea, a, document.getElementById("M17Item").selectedIndex)
}
;
window.DialogPress = function(a) {
    var b, d;
    l.Hd();
    ga = 0;
    ta(g);
    b = e;
    d = S;
    S = -1;
    if (ha)
        switch (d) {
        case 2:
            a = a == 1 ? 0 : 1;
            break;
        case 3:
        case 4:
            a = 1 - a
        }
    else
        switch (d) {
        case 2:
            a = 1 - a;
            break;
        case 3:
        case 4:
            if (a > 0)
                a -= 6;
            break;
        case 5:
            a >= 3 && M.s && ++a;
            if (a >= 5 && (M.s || !M.Q[0]))
                ++a;
            switch (a) {
            case 1:
                a = 3;
                break;
            case 2:
                a = 10;
                break;
            case 3:
                a = 5;
                break;
            case 4:
                a = 2;
                break;
            case 5:
                a = 6;
                break;
            case 6:
                a = 1;
                break;
            case 7:
                a = 4;
                break;
            default:
                b = g
            }
            b && s.Hb(a);
            b = g;
            break;
        case 6:
            if (a)
                a -= 4;
            break;
        case 7:
            if (a > 0)
                a -= 7;
            break;
        case 8:
            switch (a) {
            case 1:
                a = 9;
                break;
            case 2:
                a = 8;
                break;
            case 3:
                a = 7;
                break;
            case 4:
                a = 0;
                break;
            default:
                b = g
            }
            b && s.Hb(a);
            b = g
        }
    if (b)
        ha ? p.Bb(d, a) : s.Bb(d, a);
    n.K()
}
;
window.SetDigit = function(a) {
    ga = 0;
    s.Nb(a, e, e);
    n.K()
}
;
window.DoHint = function() {
    s.mb();
    Q.ib(6, "", "")
}
;
window.DoUndo = function() {
    s.hc();
    n.K()
}
;
window.DoRedo = function() {
    s.ld();
    n.K()
}
;
window.DoGame = function() {
    s.mb();
    Q.ib(5, "", "")
}
;
function ua() {
    s.fc();
    n.K()
}
window.SetPencil = ua;
window.DoBack = function() {
    s.gd();
    n.K()
}
;
function va() {
    s.kd();
    n.K()
}
window.DoMore = va;
function wa() {
    s.Cb();
    n.K()
}
window.DoDone = wa;
window.NextHint = function() {
    s.M ? va() : wa()
}
;
window.KPress = function(a) {
    var b;
    a = a.charCode || a.keyCode;
    b = g;
    if (a >= 48 && a <= 57)
        b = !l.fd(a - 48);
    else if (l.xd() && (a == 32 || a == 72 || a == 104))
        ua();
    else
        return e;
    n.K();
    return b
}
;
window.KDown = function(a) {
    var b, d;
    if (window.event)
        b = a.keyCode;
    else if (a.which)
        b = a.which;
    if (b >= 37 && b <= 40) {
        switch (b) {
        case 37:
            d = l.hb(2);
            break;
        case 38:
            d = l.hb(0);
            break;
        case 39:
            d = l.hb(3);
            break;
        case 40:
            d = l.hb(1)
        }
        n.K();
        return !d
    } else if (b == 13 && l.Jd())
        return g;
    return e
}
;
function ta(a) {
    if (a && S >= 0) {
        a = ia ? Math.round((Y - ka) / 3) : da + 410 - ka;
        if (a < U)
            a = U;
        document.getElementById("DialogPane").style.top = a + "px";
        a = ia ? Math.round((Z - 320) / 2) : 370 + H;
        if (a < 0)
            a = 0;
        document.getElementById("DialogPane").style.left = a + "px";
        document.getElementById("PrivacyPane").style.left = "0px";
        if (ja) {
            document.getElementById("ObscurePane").style.top = 4 + da + "px";
            document.getElementById("ObscurePane").style.left = 4 + H + "px"
        }
    } else {
        document.getElementById("DialogPane").style.left = "-4000px";
        document.getElementById("PrivacyPane").style.left = "-4000px";
        document.getElementById("ObscurePane").style.left = "-4000px";
        ja = g
    }
}
function xa(a, b, d, f, h, j) {
    var q;
    A[7].innerHTML = a ? a + "<br><hr>" : "";
    A[8].innerHTML = b ? b + "<br>&nbsp;<br>" : "";
    for (q = 0; q < f; ++q) {
        document.getElementById("DR" + q).style.display = "table-row";
        A[q].innerHTML = "<span></span>" + d[f - q - 1]
    }
    for (; q < 7; ++q)
        document.getElementById("DR" + q).style.display = "none";
    ka = f * 55 + (a ? 20 : 0) + (b ? 100 : 0);
    ia = j;
    ja = h;
    ta(e);
    l.ya(2, f)
}
window.DoSettings = function() {
    I.Hc(document.Set.play_sounds.checked ? 1 : 0, g);
    I.Pb(document.Set.show_clock.selectedIndex, g);
    I.Ic(document.Set.show_highlight.checked ? 1 : 0, g);
    I.Ec(document.Set.flash_complete.checked ? 1 : 0, g);
    I.Cc(document.Set.digit_font.selectedIndex, g);
    I.Ob(document.Set.pencil_marks.selectedIndex, g);
    I.Ac(document.Set.color_scheme.selectedIndex, g);
    I.Jc(document.Set.show_mistakes.selectedIndex, g);
    I.Mb(document.Set.blended_pencil.selectedIndex, g);
    I.Fc(document.Set.input_method.selectedIndex, g);
    I.Gc(document.Set.keep_saves.checked ? 1 : 0, g);
    document.getElementById("SettingsPane").style.left = "-4000px";
    Q.L(0)
}
;
function ya(a) {
    var b = ""
      , d = 0;
    a = a.toString();
    for (var f = /(^[a-zA-Z0-9_.]*)/; d < a.length; ) {
        var h = f.exec(a.substr(d));
        if (h != null && h.length > 1 && h[1] != "") {
            b += h[1];
            d += h[1].length
        } else {
            if (a[d] == " ")
                b += "+";
            else {
                h = a.charCodeAt(d).toString(16);
                b += "%" + (h.length < 2 ? "0" : "") + h.toUpperCase()
            }
            ++d
        }
    }
    return b
}
window.DoFeedback = function(a) {
    document.getElementById("FeedbackPane").style.left = "-4000px";
    Q.L(0);
    if (a && document.Feed.feedback.value.length > 0) {
        Q.lb(4, "http://www.enjoysudoku.com/thanks.html?overall=W2.0&comments=" + ya(document.Feed.feedback.value), 0);
        Q.db("Thank You", "Thank you for your feedback!")
    }
}
;
window.onresize = function() {
    var a;
    if (navigator.userAgent.indexOf("GoogleTV") >= 0) {
        Y = window.innerHeight;
        Z = window.innerWidth;
        if (screen.width > 1280) {
            Y = Math.floor(Y / 1.5);
            Z = Math.floor(Z / 1.5)
        }
    } else {
        Y = document.documentElement.clientHeight;
        Z = document.documentElement.clientWidth
    }
    a = Y > 1500 || Z > 1500 ? 3 : Y > 1004 || Z > 1024 ? 2 : 1;
    if (a != qa)
        switch (a) {
        case 1:
            document.body.style.backgroundImage = "url('images/kinsaleHigh.jpg')";
            qa = 1;
            break;
        case 2:
            document.body.style.backgroundImage = "url('images/kinsaleMedHigh.jpg')";
            qa = 2;
            break;
        case 3:
            document.body.style.backgroundImage = "url('images/kinsaleVeryHigh.jpg')";
            qa = 3
        }
    a = Math.round((Y - 600) / 2);
    if (a < 0)
        a = 0;
    document.getElementById("AdPane").style.top = a + "px";
    a = Math.round((Z - 120 - 692) / 3);
    if (a < 0)
        a = 0;
    else if (a > 36)
        a = 36;
    document.getElementById("AdPane").style.left = a + "px";
    W = a + 120;
    a = Math.round((Y - 95 - 488) / 3);
    if (a < 0)
        a = 0;
    else if (a > 36)
        a = 36;
    document.getElementById("LogoPane").style.top = a + "px";
    U = a + 95;
    a = Math.round((Z - 480) / 2);
    if (a < W)
        a = W;
    document.getElementById("LogoPane").style.left = a + "px";
    X && X(e)
}
;
var Q = {};
function za(a) {
    var b;
    if (a)
        Q.L(ea);
    else
        for (b = 0; b < 18; ++b)
            w[b].style.left = "-4000px";
    ta(a)
}
Q.L = function(a) {
    var b = Array(17), d, f, h, j;
    if (X != za) {
        X && X(g);
        X = za
    }
    ea = a;
    d = p.Nd(a, b);
    if (a != 0 && d < 17) {
        b[d] = "Cancel";
        ++d
    }
    f = d > 7 ? (d + 1) / 2 : d;
    h = (328 - 41 * f) / (f + 1);
    if (h < 0)
        h = 0;
    j = (Z - (d > 7 ? 360 : 320)) / 2;
    for (f = 0; f < 17; ++f)
        if (f == 0 && !b[f]) {
            fa[0] = e;
            w[0].style.left = "-4000px";
            var q = a
              , m = document.getElementById("M17Item")
              , u = void 0
              , x = void 0
              , z = void 0;
            switch (q) {
            case 2:
            case 3:
                x = q == 3 ? 3 : Tutorial.ac.length - 1;
                z = p.Vc - 1;
                if (z < 0 || z >= x)
                    z = 0;
                for (u = 0; u < x; ++u)
                    m.options[u] = new Option(Tutorial.ac[u + 1],u.toString(),u == z,u == z);
                break;
            default:
            case 4:
            case 5:
                z = p.U + 6;
                if (z < 0 || z >= 14)
                    z = 0;
                for (u = 0; u < 14; ++u)
                    m.options[u] = new Option(p.W[u] + (q == 4 && p.uc(u - 6) ? "*" : ""),u.toString(),u == z,u == z);
                break;
            case 8:
            case 9:
                x = Tutorial.ac.length;
                z = p.Vc;
                if (z < 0 || z >= x)
                    z = 0;
                for (u = 0; u < x; ++u)
                    m.options[u] = new Option(Tutorial.ac[u],u.toString(),u == z,u == z)
            }
            for (; m.length > x; )
                m.options[x] = null;
            m.selectedIndex = z;
            w[17].style.top = Math.floor(U + 50 + h) + "px";
            w[17].style.left = j + "px"
        } else if (f < d) {
            if (f == 0)
                w[17].style.left = "-4000px";
            if (b[f].charAt(0) == "D" && b[f].charAt(1) == "*") {
                w[f].innerHTML = b[f].substring(2);
                w[f].className = "menuButton gray";
                fa[f] = e
            } else {
                w[f].innerHTML = b[f];
                w[f].className = d > 7 ? "menuButton half" : "menuButton";
                fa[f] = g
            }
            w[f].style.top = Math.floor(U + 50 + h + (41 + h) * (f >= 7 ? f - 7 : f)) + "px";
            w[f].style.left = j + (f == 14 ? 100 : f >= 7 ? 200 : 0) + "px"
        } else {
            w[f].style.left = "-4000px";
            fa[f] = e
        }
    d > 7 ? l.ya(1) : l.ya(0, d)
}
;
Q.Lb = function() {
    Q.L(0)
}
;
Q.Va = function() {
    Q.L(0)
}
;
function Aa(a) {
    var b;
    if (a) {
        b = Math.floor((Z - 692 - W) / 3);
        if (b < 0)
            b = 0;
        H = b + W;
        document.getElementById("PlayPane").style.left = H + "px";
        b = Math.floor((Y - 488 - U) / 3);
        if (b < 0)
            b = 0;
        da = b + U;
        document.getElementById("PlayPane").style.top = da + "px";
        if (ca) {
            document.getElementById("HintsPane").style.left = H + 487 + "px";
            document.getElementById("HintsPane").style.top = da + 35 + "px"
        } else
            document.getElementById("HintsPane").style.left = "-4000px"
    } else {
        document.getElementById("PlayPane").style.left = "-4000px";
        document.getElementById("HintsPane").style.left = "-4000px";
        ca = g
    }
    ta(a)
}
Q.oa = function() {
    X && X(g);
    X = Aa;
    Aa(e);
    Q.vc();
    s.Ka();
    s.na();
    s.Ga();
    n.Kc(p.W[p.d + 6]);
    s.mc() ? s.ja(e) : l.ya(4);
    n.K();
    oa || (oa = setInterval(function() {
        ja || s.nd()
    }, 1E3))
}
;
Q.Ra = function() {
    if (oa) {
        clearInterval(oa);
        oa = 0
    }
    Q.L(0);
    Q.zc()
}
;
function Ba(a) {
    if (a) {
        a = Math.floor((Z - 300) / 2);
        if (a < W)
            a = W;
        document.getElementById("SettingsPane").style.left = a + "px";
        a = Math.floor((Y - 450) / 2);
        if (a < U)
            a = U;
        document.getElementById("SettingsPane").style.top = a + "px"
    } else
        document.getElementById("SettingsPane").style.left = "-4000px"
}
Q.wd = function() {
    X && X(g);
    X = Ba;
    Ba(e)
}
;
function Ca(a) {
    if (a) {
        a = Math.floor((Z - (pa == "StatsPane" ? 380 : 580)) / 2);
        if (a < W)
            a = W;
        document.getElementById(pa).style.left = a + "px";
        a = Math.floor((Y - 488) / 2);
        if (a < U)
            a = U;
        document.getElementById(pa).style.top = a + "px"
    } else
        document.getElementById(pa).style.left = "-4000px"
}
Q.gb = function(a) {
    var b;
    switch (a) {
    case 0:
        pa = "ManualPane";
        b = document.getElementById("ManualDone");
        break;
    case 2:
        pa = "StatsPane";
        b = document.getElementById("StatsDone");
        a = {};
        a.a = "";
        P.ad(a);
        document.getElementById("statistics").innerHTML = a.a
    }
    X && X(g);
    X = Ca;
    Ca(e);
    l.ya(6, b)
}
;
DoEndHTML = function() {
    Q.L(0)
}
;
function Da(a) {
    if (a) {
        a = Math.floor((Z - 400) / 2);
        if (a < W)
            a = W;
        document.getElementById("FeedbackPane").style.left = a + "px";
        a = Math.floor((Y - 350) / 2);
        if (a < U)
            a = U;
        document.getElementById("FeedbackPane").style.top = a + "px"
    } else
        document.getElementById("FeedbackPane").style.left = "-4000px"
}
Q.vd = function() {
    X && X(g);
    X = Da;
    Da(e);
    l.ya(3);
    document.Feed.feedback.value = "";
    document.Feed.feedback.focus()
}
;
Q.Ab = function() {
    setTimeout(function() {
        if (I.ta)
            document.getElementById("sound_element").innerHTML = "<embed src='images/click.wav' hidden=true autostart=true loop=false>"
    }, 1)
}
;
Q.ee = function(a) {
    document.location.href = a
}
;
Q.db = function(a, b) {
    Q.Ib(0, a, b)
}
;
Q.Wa = function(a) {
    Q.db("Sorry", a)
}
;
Q.B = function() {
    ra("config", "a" + String.fromCharCode(48 + (I.P ? 2 : I.Ba ? 1 : 0)) + "c" + String.fromCharCode(48 + I.va) + "D" + String.fromCharCode(65 + p.U + 7) + "F" + (I.ra ? "1" : "0") + "H" + (I.ia ? "1" : "0") + "I" + String.fromCharCode(48 + I.wa) + "K" + (I.Za ? "1" : "0") + "M" + String.fromCharCode(48 + I.ha) + "P" + String.fromCharCode(48 + I.Da) + "Q" + String.fromCharCode(48 + I.ba) + "S" + (I.ta ? "1" : "0") + "X" + String.fromCharCode(65 + I.Aa), 365)
}
;
Q.Ad = function() {
    var a, b, d, f;
    f = (a = sa("config")) ? a.length : 0;
    for (d = 0; d + 2 <= f; d += 2)
        switch (a.charAt(d)) {
        case "A":
            b = parseInt(a.charAt(d + 1));
            if (b == 0 || b == 1)
                I.Mb(b + 1, e);
            break;
        case "a":
            b = parseInt(a.charAt(d + 1));
            if (b >= 0 || b <= 2)
                I.Mb(b, e);
            break;
        case "C":
            b = parseInt(a.charAt(d + 1));
            if (b == 0 || b == 1)
                I.Pb(b == 1 ? 2 : 0, e);
            break;
        case "c":
            b = parseInt(a.charAt(d + 1));
            if (b >= 0 || b <= 2)
                I.Pb(b, e);
            break;
        case "D":
            b = a.charCodeAt(d + 1) - 65 - 7;
            if (b >= -7 && b <= 9)
                p.U = b;
            break;
        case "F":
            b = parseInt(a.charAt(d + 1));
            if (b == 0 || b == 1)
                I.Ec(b, e);
            break;
        case "H":
            b = parseInt(a.charAt(d + 1));
            if (b == 0 || b == 1)
                I.Ic(b, e);
            break;
        case "I":
            b = parseInt(a.charAt(d + 1));
            if (b >= 0 || b <= 1)
                I.Jc(b, e);
            break;
        case "K":
            b = parseInt(a.charAt(d + 1));
            if (b == 0 || b == 1)
                I.Gc(b, e);
            break;
        case "M":
            b = parseInt(a.charAt(d + 1));
            if (b >= 0 || b <= 2)
                I.Fc(b, e);
            break;
        case "P":
            b = parseInt(a.charAt(d + 1));
            if (b >= 0 || b <= 3)
                I.Ob(b, e);
            break;
        case "Q":
            b = parseInt(a.charAt(d + 1));
            if (b >= 0 || b <= 5)
                I.Ac(b, e);
            break;
        case "S":
            b = parseInt(a.charAt(d + 1));
            if (b == 0 || b == 1)
                I.Hc(b, e);
            break;
        case "X":
            b = a.charCodeAt(d + 1) - 65;
            if (b >= 0 || b <= 3)
                I.Cc(b, e)
        }
    document.Set.play_sounds.checked = I.ta;
    document.Set.show_clock.selectedIndex = I.va;
    document.Set.show_highlight.checked = I.ia;
    document.Set.flash_complete.checked = I.ra;
    document.Set.digit_font.selectedIndex = I.Aa;
    document.Set.pencil_marks.selectedIndex = I.Da;
    document.Set.color_scheme.selectedIndex = I.ba;
    document.Set.show_mistakes.selectedIndex = I.wa;
    document.Set.blended_pencil.selectedIndex = I.P ? 2 : I.Ba ? 1 : 0;
    document.Set.input_method.selectedIndex = I.ha;
    document.Set.keep_saves.checked = I.Za
}
;
Q.ed = function(a) {
    setTimeout(function() {
        s.Yc(a);
        n.K()
    }, 400)
}
;
Q.lb = function(a, b, d) {
    la != 0 && Q.ab();
    switch (a) {
    case 1:
    case 2:
    case 5:
        na = setTimeout(function() {
            Q.bd()
        }, 500)
    }
    la = a;
    T || (T = new XMLHttpRequest);
    T.onreadystatechange = DownloadStep;
    T.open(d ? "POST" : "GET", b, e);
    T.send(d ? d : null)
}
;
Q.Dc = function(a) {
    ma = setTimeout(function() {
        Q.ab()
    }, a * 1E3)
}
;
Q.ab = function() {
    if (la) {
        T.abort();
        Q.Eb(0)
    }
}
;
DownloadStep = function() {
    if (T.readyState == 4)
        T.status >= 200 && T.status < 400 ? Q.Eb(T.responseText) : Q.Eb(0)
}
;
Q.Eb = function(a) {
    var b, d, f;
    if (la) {
        b = la;
        la = 0;
        if (ma) {
            clearTimeout(ma);
            ma = 0
        }
        if (na) {
            clearTimeout(na);
            na = 0
        }
        switch (b) {
        case 1:
        case 2:
            if (a && a.length >= 86 && a.length < 96 && a.charAt(81) == " " && a.charAt(82) == "#" && a.charAt(83) == " ") {
                d = a.substring(0, 81);
                M.Ja(d);
                for (f = 86; f < a.length && a.charCodeAt(f) >= 48 && a.charCodeAt(f) <= 57; ++f)
                    ;
                M.e.a = a.substring(84, f);
                a = a.charCodeAt(84);
                if (b == 2 && a >= 65 && a < 77) {
                    p.z[a - 65 + 6] = Q.za();
                    p.H[a - 65 + 6].a = "N" + d
                }
                Q.oa()
            } else
                p.fb();
            break;
        case 3:
            if (I.va > 0) {
                if (a && a.length > 3 && a.charAt(0) == "O" && a.charAt(1) == "K" && a.charAt(2) == "-")
                    s.ka(a.substring(3));
                else {
                    b = {};
                    b.a = "";
                    s.$c(b);
                    s.ka(b.a)
                }
                s.ja(e)
            }
            break;
        case 5:
            if (a && a.length > 3 && a.charAt(0) == "O" && a.charAt(1) == "K" && a.charAt(2) == "-")
                s.ka(a.substring(3));
            else
                a ? Q.Wa(a) : s.ka("T[Unable to contact the hint server!]");
            s.mc() && s.ja(e)
        }
    }
}
;
Q.bd = function() {
    na = 0
}
;
Q.Ib = function(a, b, d) {
    var f = Array(6), h;
    ha = e;
    S = a;
    switch (a) {
    case 0:
    case 1:
        f[0] = "OK";
        h = 1;
        break;
    case 2:
        f[0] = "OK";
        h = 1;
        f[h++] = "Cancel";
        break;
    case 3:
    case 4:
        f[0] = "OK";
        f[1] = "Cancel";
        h = 2
    }
    xa(b, d, f, h, g, e)
}
;
Q.ib = function(a, b, d) {
    var f = Array(6), h = {}, j, q, m;
    ha = g;
    S = a;
    q = g;
    m = e;
    switch (a) {
    case 0:
    case 1:
        f[0] = "OK";
        j = 1;
        break;
    case 2:
        f[0] = "OK";
        f[1] = "Cancel";
        j = 2;
        break;
    case 3:
    case 4:
        for (j = 0; j < 5; ++j)
            if (p.O[j] == 0)
                f[j] = "Empty";
            else {
                Q.rd(h, p.O[j]);
                f[j] = h.a
            }
        f[5] = "Cancel";
        j = 6;
        break;
    case 5:
        j = 0;
        if (M.s) {
            M.pd(h);
            h = o.Mc(h, 0, g);
            if (h == 1)
                f[j++] = "Play It";
            else
                b = h == 0 ? "Puzzle cannot be solved." : "Puzzle is not fully entered.";
            f[j++] = "Throw Away"
        } else {
            f[j++] = "Give Up";
            if (M.Q[0])
                f[j++] = "Return to Bookmark"
        }
        f[j++] = "Save Game and Exit";
        M.s || (f[j++] = "Set Bookmark");
        f[j++] = "More Choices";
        f[j++] = "Main Menu";
        f[j++] = "Return to Puzzle";
        q = e;
        m = g;
        break;
    case 6:
        f[0] = "Show Solution";
        f[1] = "Fill in Pencil Marks";
        f[2] = "Hint";
        f[3] = "Return to Puzzle";
        j = 4;
        m = g;
        break;
    case 7:
        j = 0;
        f[j++] = "Mirror Diagonally";
        f[j++] = "Mirror Vertically";
        f[j++] = "Mirror Horizontally";
        f[j++] = "Rotate 90\u00b0 CCW";
        f[j++] = "Rotate 180\u00b0";
        f[j++] = "Rotate 90\u00b0 CW";
        f[j++] = "Return to Puzzle";
        q = e;
        m = g;
        break;
    case 8:
        j = 0;
        if (M.s)
            f[j++] = "Clear Board";
        else
            f[j++] = "Start Over";
        f[j++] = "Rotate and Mirror";
        f[j++] = "Save and Continue";
        f[j++] = "Clear All Pencil Marks";
        f[j++] = "Return to Puzzle";
        q = e;
        m = g
    }
    xa(b, d, f, j, q, m)
}
;
Q.za = function() {
    var a = new Date;
    return Math.floor(((a.getTime() - a.getTimezoneOffset() * 6E4) / 36E5 - 4 - 348432) / 24)
}
;
Q.Rd = function() {
    var a = new Date;
    return 24 - Math.floor((a.getTime() - a.getTimezoneOffset() * 6E4) / 36E5 - 4 - 348432) % 24
}
;
Q.vc = function() {
    var a, b;
    b = n.Qc();
    for (a = 0; a < 9; ++a) {
        D[a].innerHTML = "<span></span>" + F[b][a];
        D[a].style.fontSize = b ? "32px" : "42px"
    }
}
;
Q.Pd = function(a) {
    var b, d, f, h, j, q;
    if (I.ba == 0)
        return a;
    h = f = 0;
    q = g;
    b = "";
    for (d = 0; d >= 0; ) {
        d = -1;
        j = a.indexOf("yellow", f);
        if (j >= 0 && (d < 0 || j < d)) {
            d = j;
            h = 0;
            q = g
        }
        j = a.indexOf("Yellow", f);
        if (j >= 0 && (d < 0 || j < d)) {
            d = j;
            h = 0;
            q = e
        }
        j = a.indexOf("pink", f);
        if (j >= 0 && (d < 0 || j < d)) {
            d = j;
            h = 1;
            q = g
        }
        j = a.indexOf("Pink", f);
        if (j >= 0 && (d < 0 || j < d)) {
            d = j;
            h = 1;
            q = e
        }
        j = a.indexOf("green", f);
        if (j >= 0 && (d < 0 || j < d)) {
            d = j;
            h = 2;
            q = g
        }
        j = a.indexOf("Green", f);
        if (j >= 0 && (d < 0 || j < d)) {
            d = j;
            h = 2;
            q = e
        }
        j = a.indexOf("blue", f);
        if (j >= 0 && (d < 0 || j < d)) {
            d = j;
            h = 3;
            q = g
        }
        j = a.indexOf("Blue", f);
        if (j >= 0 && (d < 0 || j < d)) {
            d = j;
            h = 3;
            q = e
        }
        if (d >= 0) {
            b += a.substring(f, d);
            if (q) {
                b += ba[h][I.ba].charAt(0).toUpperCase();
                b += ba[h][I.ba].substring(1)
            } else
                b += ba[h][I.ba];
            f = d + ba[h][0].length
        }
    }
    if (f < a.length)
        b += a.substring(f);
    return b
}
;
Q.$d = function() {
    return "T[Internal hints are not available!]"
}
;
Q.fb = k();
Q.fe = k();
Q.ce = function() {
    return 0
}
;
Q.Fb = function() {
    return (new Date).getTime() / 6E4
}
;
Q.rd = function(a, b) {
    var d = new Date;
    d.setTime = b * 60 * 1E3;
    a.a = d.toLocaleString();
    d = a.a.lastIndexOf(" ");
    if (d < 0)
        d = a.a.length;
    a.a = a.a.substring(0, d);
    d = a.a.indexOf(" ");
    if (d > 3)
        a.a = a.a.substring(0, 3) + a.a.substring(d, a.a.length);
    d = a.a.lastIndexOf(":");
    if (d > 0 && d != a.a.indexOf(":") && d + 3 < a.a.length)
        a.a = a.a.substring(0, d) + a.a.substring(d + 3, a.a.length)
}
;
function Ea(a) {
    var b, d, f, h;
    h = a && typeof a == "string" ? a.length : 0;
    for (d = 0; ; ) {
        if (d >= h)
            break;
        b = a.charAt(d);
        if (b < "0" || b > "9")
            break;
        ++d
    }
    if (d > 0) {
        f = parseInt(a.substring(0, d));
        ++d
    } else
        f = 0;
    for (b = 0; b < 18; ++b)
        if (d >= h || a.charAt(d) == "Z" || h < d + 82) {
            p.z[b] = 0;
            p.H[b].a = "";
            ++d
        } else {
            p.z[b] = f;
            p.H[b].a = a.substring(d, d + 82);
            p.Ea[b] = e;
            d += 82
        }
}
function $(a) {
    var b;
    for (b = 0; b < a.length; ++b)
        a[b] = parseInt(a[b])
}
Q.Cd = function() {
    var a, b, d;
    try {
        d = sa("state");
        d = unescape(d);
        a = JSON.parse(d);
        if (!a || typeof a != "object")
            a = {}
    } catch (f) {
        a = {}
    }
    if (a) {
        if (a.ob && typeof a.ob == "string") {
            d = a.ob.split("A");
            if (d.length == 182) {
                $(d);
                M.sc(d, 0, d.length)
            }
        }
        if (a.Q && typeof a.Q == "string") {
            d = a.Q.split("A");
            if (d.length == 182) {
                $(d);
                M.Q = d
            }
        }
        a.z && Ea(a.z)
    }
    try {
        d = sa("saves");
        d = unescape(d);
        a = JSON.parse(d);
        if (!a || typeof a != "object")
            a = {}
    } catch (h) {
        a = {}
    }
    if (a) {
        if (a.n && typeof a.n == "object" && typeof a.n.length == "number" && a.n.length == 5 && a.O && typeof a.O == "object" && typeof a.O.length == "number" && a.O.length == 5)
            for (b = 0; b < 5; ++b)
                if (a.n[b] && a.O[b] && typeof a.n[b] == "string") {
                    d = a.n[b].split("A");
                    if (d.length == 182) {
                        $(d);
                        p.n[b] = d;
                        p.O[b] = parseInt(a.O[b])
                    }
                }
        a.z && Ea(a.z)
    }
    try {
        d = sa("stats");
        d = unescape(d);
        a = JSON.parse(d);
        if (!a || typeof a != "object")
            a = {}
    } catch (j) {
        a = {}
    }
    if (a)
        if (a.F && typeof a.F == "object" && typeof a.F.length == "number" && a.F.length == 80 && a.G && typeof a.G == "object" && typeof a.G.length == "number" && a.G.length == 80 && a.r && typeof a.r == "object" && typeof a.r.length == "number" && a.r.length == 80 && a.I && typeof a.I == "object" && typeof a.I.length == "number" && a.I.length == 80 && a.w && typeof a.w == "object" && typeof a.w.length == "number" && a.w.length == 80 && a.C && typeof a.C == "object" && typeof a.C.length == "number" && a.C.length == 80) {
            P.F = a.F;
            P.G = a.G;
            P.r = a.r;
            P.I = a.I;
            P.w = a.w;
            P.C = a.C
        } else {
            if (a.F && typeof a.F == "string") {
                d = a.F.split("A");
                if (d.length == 80) {
                    $(d);
                    P.F = d
                }
            }
            if (a.G && typeof a.G == "string") {
                d = a.G.split("A");
                if (d.length == 80) {
                    $(d);
                    P.G = d
                }
            }
            if (a.r && typeof a.r == "string") {
                d = a.r.split("A");
                if (d.length == 80) {
                    $(d);
                    P.r = d
                }
            }
            if (a.I && typeof a.I == "string") {
                d = a.I.split("A");
                if (d.length == 80) {
                    $(d);
                    P.I = d
                }
            }
            if (a.w && typeof a.w == "string") {
                d = a.w.split("A");
                if (d.length == 80) {
                    $(d);
                    P.w = d
                }
            }
            if (a.C && typeof a.C == "string") {
                d = a.C.split("A");
                if (d.length == 80) {
                    $(d);
                    P.C = d
                }
            }
        }
    try {
        d = sa("undo");
        d = unescape(d);
        a = JSON.parse(d);
        if (!a || typeof a != "object")
            a = {}
    } catch (q) {
        a = {}
    }
    if (a)
        if (a.ub && typeof a.ub == "string") {
            a = a.ub.split("B");
            for (b = 0; b < a.length && M.k < 64; ++b) {
                d = a[b].split("A");
                if (d.length == 81) {
                    $(d);
                    M.Fa[M.k] = d;
                    M.k += 1
                }
            }
        }
}
;
Q.zc = function() {
    var a, b, d;
    s.mb();
    a = {};
    if (M.h) {
        if (M.Y[0] > 0)
            d = M.Y;
        else {
            d = Array(M.xa(0, -1E5));
            M.xa(d, 0)
        }
        a.ob = d.join("A")
    } else
        a.ob = 0;
    a.Q = M.h && M.Q[0] > 0 ? M.Q.join("A") : 0;
    b = a;
    var f;
    f = Q.za();
    str = f.toString() + "$";
    for (d = 0; d < 18; ++d)
        str += p.z[d] >= f && p.z[d] < f + 7 && p.H[d].a.length == 82 ? p.H[d].a : "Z";
    b.z = str;
    d = encodeURIComponent(JSON.stringify(a));
    ra("state", d, 365);
    a = {};
    a.n = p.n.slice(0);
    a.O = p.O.slice(0);
    for (b = 0; b < 5; ++b)
        if (p.n[b] <= 0) {
            a.n[b] = 0;
            a.O[b] = 0
        } else
            a.n[b] = a.n[b].join("A");
    d = encodeURIComponent(JSON.stringify(a));
    ra("saves", d, 365);
    a = {};
    a.F = P.F.join("A");
    a.G = P.G.join("A");
    a.r = P.r.join("A");
    a.I = P.I.join("A");
    a.w = P.w.join("A");
    a.C = P.C.join("A");
    d = encodeURIComponent(JSON.stringify(a));
    ra("stats", d, 365);
    a = {};
    if (M.h && M.k > 0) {
        d = M.Fa.slice(M.k > 6 ? M.k - 6 : 0, M.k);
        for (b = 0; b < d.length; ++b)
            d[b] = d[b].join("A");
        a.ub = d.join("B")
    } else
        a.ub = 0;
    d = encodeURIComponent(JSON.stringify(a));
    ra("undos", d, 365)
}
;
Q.ge = k();
var s = {};
s.j = 0;
s.g = 1;
s.m = 0;
s.ea = 0;
s.Ya = 0;
s.ca = -1;
s.p = Array(3);
for (i = 0; i < 3; ++i)
    s.p[i] = Array(81);
s.vb = 0;
s.pb = Array(81);
s.Wb = 0;
s.wb = 0;
s.Nb = function(a, b, d) {
    if (s.j == 2) {
        s.g != a && n.f(-1);
        s.g = a;
        s.xb(s.m) && I.ta && Q.Ab();
        n.A(s.g - 1, s.g <= 9 && M.R[s.g - 1] >= 9 && s.V != 1 ? 2 : 0)
    } else {
        n.A(s.g - 1, s.g <= 9 && M.R[s.g - 1] >= 9 && s.V != 1 ? 2 : 0);
        if (I.ha == 0 && d && s.j == 1 && s.g == a && s.V == 0) {
            s.j = 0;
            n.f(-1)
        } else {
            if (s.V == 1 && s.g == a && (a == 3 || a == 6))
                colorFlip = colorFlip ? 0 : -1;
            s.j = 1;
            s.g = a;
            n.A(s.g - 1, 1);
            if (I.ia || s.Ya)
                n.f(-1);
            s.ea && I.P && b && s.fc()
        }
    }
}
;
s.zd = function(a, b) {
    if (b < 0 || b >= 81)
        s.Nb(a, -1, -1);
    else {
        if (s.g != a) {
            if (s.j == 1)
                n.A(s.g - 1, s.g <= 9 && M.R[s.g - 1] >= 9 && s.V != 1 ? 2 : 0);
            n.f(-1);
            s.g = a;
            n.A(s.g - 1, s.j == 1 ? 1 : s.g <= 9 && M.R[s.g - 1] >= 9 && s.V != 1 ? 2 : 0)
        }
        M.c[b] >= 0 && (M.c[b] & 512) == 0 && (M.c[b] >> 11 & 15) != a - 1 && M.fa(b, 0, 0);
        s.xb(b) && I.ta && Q.Ab()
    }
}
;
s.ec = function(a) {
    var b;
    if (s.V == 1) {
        switch (s.g) {
        case 1:
            b = 6;
            break;
        case 2:
            b = 8;
            break;
        case 3:
            b = colorFlip ? 8 : 6;
            colorFlip = colorFlip ? 0 : -1;
            break;
        case 4:
            b = 7;
            break;
        case 5:
            b = 9;
            break;
        case 6:
            b = colorFlip ? 9 : 7;
            colorFlip = colorFlip ? 0 : -1;
            break;
        default:
        case 7:
            b = 0
        }
        s.p[2][a] = b;
        n.f(a)
    } else if (s.Ya)
        if (M.c[a] >= 0) {
            s.ma = -1;
            s.Nb((M.c[a] >> 11 & 15) + 1, -1, -1)
        } else {
            s.ma = 0;
            n.f(-1)
        }
    else if (s.j != 1) {
        n.f(s.m);
        if (I.ha == 0 && s.j == 2 && s.m == a) {
            s.j = 0;
            n.f(-1)
        } else {
            if (s.j == 0) {
                s.j = 2;
                n.f(-1)
            }
            n.f(a);
            if (M.c[a] >= 0 && (M.c[a] >> 11 & 15) + 1 != s.g) {
                s.g = (M.c[a] >> 11 & 15) + 1;
                n.f(-1)
            }
        }
    } else
        s.xb(a) && I.ta && Q.Ab();
    s.m = a
}
;
s.fc = function() {
    if (I.ha == 1 && s.j == 2) {
        if (s.j == 2 || !s.ea)
            s.ea = !s.ea;
        s.j = s.j == 2 ? 1 : 2;
        n.A(10, s.j == 2 ? 2 : 0);
        n.f(I.ia ? -1 : s.m);
        n.A(s.g - 1, s.j == 2 ? s.g <= 9 && M.R[s.g - 1] >= 9 ? 2 : 0 : 1)
    } else {
        s.ea = !s.ea;
        n.A(10, s.ea ? 1 : 0)
    }
}
;
s.jd = function() {
    var a = {};
    a.a = "";
    var b = {};
    b.a = "";
    M.qd(a);
    b.a = "board=";
    b.a += typeof a == "string" ? a : a.a;
    s.ka("T[ ]");
    s.ja(-1);
    Q.lb(5, "http://www.enjoysudoku.com/cgi/q?hint&nomedusa", b.a);
    Q.Dc(20)
}
;
s.hc = function() {
    if (s.ca < 0) {
        M.da();
        s.ca = M.k - 1;
        n.Qb(-1)
    }
    s.ca > 0 && --s.ca;
    M.Db(s.ca);
    n.A(12, s.ca > 0 ? 0 : 3);
    n.A(13, s.ca < M.k - 1 ? 0 : 3)
}
;
s.ld = function() {
    if (s.ca < M.k - 1)
        s.ca += 2;
    s.hc()
}
;
s.mb = function() {
    if (s.ca >= 0) {
        s.ca == M.k - 1 && --M.k;
        n.Qb(0);
        s.ca = -1;
        s.na()
    }
}
;
s.Zd = k();
s.hd = function() {
    M.$a();
    n.f(-1)
}
;
s.md = function() {
    s.gc()
}
;
s.gd = function() {
    var a;
    if (s.sa && s.S > 1) {
        for (a = 0; a < 81; ++a)
            s.p[0][a] = 0;
        a = s.S - 1;
        s.M = s.sa;
        s.S = 0;
        if (s.$ && M.Y[0] <= 0 && M.k > 0) {
            s.$ = 0;
            M.Db(M.k - 1);
            --M.k
        }
        do
            s.ja(s.S >= a - 1);
        while (s.S < a)
    }
}
;
s.kd = function() {
    s.M && s.ja(-1)
}
;
s.Cb = function() {
    var a;
    s.M = 0;
    s.sa = 0;
    s.Ya = 0;
    Q.ab();
    for (a = 0; a < 81; ++a)
        s.p[0][a] = 0;
    s.ma = s.V == 1 ? 2 : -1;
    s.vb = 0;
    if (M.Y[0] > 0) {
        a = M.h;
        M.Ua(M.Y, 0, 182);
        if (!a)
            M.h = M.s = 0;
        M.Y[0] = 0;
        n.Kc(p.W[p.d + 6])
    }
    if (M.h) {
        s.Ka();
        n.Lc(0);
        n.f(-1);
        s.qc()
    } else
        Q.Ra()
}
;
s.nd = function() {
    if (M.h && !M.s) {
        M.v += 1;
        s.Ga()
    }
}
;
s.Ga = function() {
    var a = {};
    a.a = "";
    var b;
    if (p.q == 5)
        a.a = "Entering";
    else if (p.q == 9 || p.q == 7 || p.d < -3 || p.q == 8)
        a.a = "";
    else if (I.va >= 2) {
        a.a = "Time: ";
        if (M.v > 59999) {
            a.a += (M.v >= 6E5 ? 9999 : Math.floor(M.v / 60)).toString();
            a.a += "m"
        } else {
            a.a += Math.floor(M.v / 60).toString();
            a.a += ":";
            b = M.v % 60;
            if (b < 10)
                a.a += (0).toString();
            a.a += b.toString()
        }
    } else
        a.a = "";
    n.Od(a)
}
;
s.xb = function(a) {
    if (s.g >= 10)
        if (M.c[a] >= 0)
            if ((M.c[a] & 512) == 0) {
                M.da();
                M.fa(a, 0, 0)
            } else
                return 0;
        else if ((M.c[a] & 511) != M.bb(a)) {
            M.da();
            M.fa(a, -1, 0)
        } else
            return 0;
    else if (s.ea)
        if (M.c[a] >= 0)
            return 0;
        else {
            M.da();
            M.c[a] ^= 1 << s.g - 1;
            n.f(a)
        }
    else if (M.c[a] >= 0 && (M.c[a] & 512) == 0 && (M.c[a] >> 11 & 15) == s.g - 1) {
        M.da();
        M.fa(a, 0, 0)
    } else if (s.j != 1 && (M.c[a] & 512) == 0 || !(M.c[a] >= 0)) {
        M.da();
        M.fa(a, s.g, 0);
        s.qc()
    } else
        return 0;
    M.k == 1 && s.na();
    return -1
}
;
s.qc = function() {
    var a = {};
    a.a = "";
    var b, d;
    if (M.Pa >= 81) {
        for (b = 0; b < 9; ++b)
            if (M.ua[b] != 511 || M.qa[b] != 511 || M.pa[b] != 511) {
                Q.Wa("That is not a valid solution!");
                return 0
            }
        b = M.e.a.charAt(0).charCodeAt(0) - "A".charCodeAt(0);
        if (b < 0 || b >= 12)
            b = M.e.a.charAt(0) == "V" ? M.e.a.charAt(1).charCodeAt(0) - 48 - 7 : M.e.a.charAt(0) == "U" || M.e.a.charAt(0) == "W" ? 12 : -7;
        P.Fd(b, M.J, M.N > 0, M.T, M.v);
        d = p.Kd(M.e, M.t);
        M.h = M.s = 0;
        s.j = 0;
        n.f(-1);
        if (I.va > 0) {
            a.a = "nT'Your time: ";
            b = M.v;
            a.a += Math.floor(b / 60).toString();
            a.a += ":";
            b %= 60;
            if (b < 10)
                a.a += "0";
            a.a += b.toString();
            if (M.N > 0) {
                a.a += " (";
                b = M.v - M.N;
                a.a += Math.floor(b / 60).toString();
                a.a += ":";
                b %= 60;
                if (b < 10)
                    a.a += "0";
                a.a += b.toString();
                a.a += " + ";
                b = M.N;
                a.a += Math.floor(b / 60).toString();
                a.a += ":";
                b %= 60;
                if (b < 10)
                    a.a += "0";
                a.a += b.toString();
                a.a += " for hints)"
            }
            a.a += ".'"
        } else
            a.a = "nT'Puzzle complete.'";
        s.ka(a.a);
        s.ja(-1);
        a.a = "http://www.enjoysudoku.com/cgi/q?done=";
        a.a += typeof M.e == "string" ? M.e : M.e.a;
        a.a += "&time=";
        a.a += M.v.toString();
        a.a += "&ap=";
        a.a += typeof (M.J ? "1" : "0") == "string" ? M.J ? "1" : "0" : M.J ? "1" : "0".a;
        a.a += "&pure=";
        a.a += typeof (M.T ? "1" : "0") == "string" ? M.T ? "1" : "0" : M.T ? "1" : "0".a;
        a.a += "&penalty=";
        a.a += M.N.toString();
        a.a += "&incorrect=";
        a.a += (M.la * M.rb[p.d > 0 ? p.d : 0]).toString();
        if (d)
            a.a += "&again";
        Q.lb(3, a.a, "confirm=1");
        Q.db("Congratulations!", "Puzzle Complete!");
        return -1
    }
    return 0
}
;
s.ka = function(a) {
    s.M = s.sa = n.Qd(Q.Pd(a));
    s.S = 0;
    s.Xb = -1;
    s.nb = M.Y[0] <= 0 ? -1 : 0;
    s.$ = 0;
    s.$b = -1
}
;
s.mc = function() {
    return !!s.sa
}
;
s.he = function() {
    var a;
    if (s.$b) {
        s.$b = 0;
        s.sa && s.ja(-1)
    } else if (s.sa) {
        for (a = 0; a < 81; ++a)
            s.p[0][a] = 0;
        a = s.S;
        s.M = s.sa;
        s.S = 0;
        if (s.$ && M.Y[0] <= 0 && M.k > 0) {
            s.$ = 0;
            M.Db(M.k - 1);
            --M.k
        }
        do
            s.ja(s.S >= a - 1);
        while (s.S < a)
    }
}
;
s.ja = function(a) {
    var b = {};
    b.a = "";
    var d, f, h, j, q, m, u, x, z, r, t, v;
    s.$b = 0;
    if (s.M) {
        d = s.M;
        s.M = 0;
        n.A(16, 3);
        u = 6;
        t = 0;
        v = -1;
        r = 0;
        z = -1;
        q = 0;
        s.S += 1;
        s.Yb = -1;
        h = d.length;
        for (f = 0; f < h && !r; )
            switch (d.charAt(f)) {
            case "\t":
                ++f;
                break;
            case "A":
                if (!s.$ && s.nb) {
                    M.da();
                    s.$ = -1
                }
                M.$a();
                ++f;
                break;
            case "a":
                if (!s.$ && s.nb) {
                    M.da();
                    s.$ = -1
                }
                for (m = 0; m < 81; ++m)
                    M.c[m] >= 0 || (M.c[m] = -16384);
                ++f;
                break;
            case "B":
                if (h - f < 2)
                    r = -1;
                else {
                    m = d.charAt(f + 1).charCodeAt(0) - 48;
                    if (m < 0 || m >= 9)
                        r = -1;
                    else {
                        for (j = 0; j < 9; ++j)
                            s.p[0][o.cells[18 + m][j]] = u;
                        f += 2
                    }
                }
                break;
            case "C":
                if (h - f < 2)
                    r = -1;
                else {
                    j = d.charAt(f + 1).charCodeAt(0) - 48;
                    if (j < 0 || j > 8)
                        r = -1;
                    else {
                        for (m = j; m < 81; m += 9)
                            s.p[0][m] = u;
                        f += 2
                    }
                }
                break;
            case "D":
                if (h - f < 2)
                    r = -1;
                else {
                    j = d.charAt(f + 1).charCodeAt(0) - 48;
                    if (j < 0 || j >= 9)
                        r = -1;
                    else {
                        j = 1 << j;
                        for (m = 0; m < 81; ++m)
                            if (M.c[m] >= 0 && 1 << (M.c[m] >> 11 & 15) == j)
                                s.p[0][m] = u;
                        f += 2
                    }
                }
                break;
            case "d":
                if (h - f < 2)
                    r = -1;
                else {
                    j = d.charAt(f + 1).charCodeAt(0) - 48;
                    if (j < 0 || j >= 9)
                        r = -1;
                    else {
                        j = 1 << j;
                        for (m = 0; m < 81; ++m)
                            if (!(M.c[m] >= 0) && (M.c[m] & 511 & j) != 0)
                                s.p[0][m] = u;
                        f += 2
                    }
                }
                break;
            case "E":
                z = 0;
                f = h;
                break;
            case "e":
                if (M.Y[0] <= 0)
                    M.h = M.s = 0;
                ++f;
                break;
            case "H":
                if (h - f < 2)
                    r = -1;
                else {
                    switch (d.charAt(f + 1)) {
                    case "0":
                    case "1":
                    case "2":
                    case "3":
                    case "4":
                    case "5":
                    case "6":
                    case "7":
                    case "8":
                    case "9":
                        q = d.charAt(f + 1).charCodeAt(0) - 48;
                        break;
                    case "B":
                        u = 9;
                        break;
                    case "G":
                        u = 8;
                        break;
                    case "R":
                        u = 7;
                        break;
                    case "Y":
                        u = 6;
                        break;
                    case "W":
                        u = 0;
                        break;
                    default:
                        r = -1
                    }
                    r || (f += 2)
                }
                break;
            case "h":
                ++f;
                break;
            case "L":
                if (h - f < 82)
                    r = -1;
                else {
                    b.a = "";
                    for (m = 0; m < 81; ++m)
                        b.a += d.charAt(f + m + 1);
                    m = M.h;
                    j = parseInt(M.e.a.substring(1));
                    M.rc(b.a);
                    if (!m) {
                        M.h = M.s = 0;
                        M.e.a = "X";
                        M.e.a += j.toString()
                    }
                    for (m = 0; m < 81; ++m)
                        s.p[0][m] = 0;
                    f += 82
                }
                break;
            case "l":
                if (h - f < 4)
                    r = -1;
                s.Yb = -1;
                f += 4;
                break;
            case "M":
                if (h - f < 2)
                    r = -1;
                else if (t) {
                    t = 0;
                    ++f
                } else {
                    s.M = d.substring(f + 1);
                    f = h;
                    n.A(16, 0)
                }
                break;
            case "m":
                s.vb = -1;
                for (m = 0; m < 81; ++m)
                    s.pb[m] = 0;
                ++f;
                break;
            case "N":
                t = -1;
                ++f;
                break;
            case "n":
                v = -1;
                ++f;
                break;
            case "O":
                if (h - f < 3)
                    r = -1;
                else {
                    m = (d.charAt(f + 1).charCodeAt(0) - 48) * 10 + (d.charAt(f + 2).charCodeAt(0) - 48);
                    if (m < 0 || m >= 81)
                        r = -1;
                    else {
                        if (q != 0) {
                            j = u != 0 ? u - 6 + 1 : 0;
                            x = (q - 1) * 3;
                            s.pb[m] = s.pb[m] & ~(7 << x) | j << x
                        } else
                            s.p[0][m] = u;
                        f += 3
                    }
                }
                break;
            case "P":
                if (h - f < 5)
                    r = -1;
                else {
                    m = (d.charAt(f + 1).charCodeAt(0) - 48) * 10 + (d.charAt(f + 2).charCodeAt(0) - 48);
                    j = (R.yb(d.charAt(f + 3)) << 6) + R.yb(d.charAt(f + 4));
                    if (m < 0 || m >= 81 || j < 0 || j > 511)
                        r = -1;
                    else {
                        if (!s.$ && s.nb) {
                            M.da();
                            s.$ = -1
                        }
                        M.c[m] >= 0 && M.fa(m, 0, 0);
                        M.c[m] = j | -16384;
                        f += 5
                    }
                }
                break;
            case "R":
                if (h - f < 2)
                    r = -1;
                else {
                    m = d.charAt(f + 1).charCodeAt(0) - 48;
                    if (m < 0 || m >= 9)
                        r = -1;
                    else {
                        m = m * 9 + 0;
                        for (j = 0; j < 9; ++j,
                        ++m)
                            s.p[0][m] = u;
                        f += 2
                    }
                }
                break;
            case "S":
                if (h - f < 4)
                    r = -1;
                else {
                    m = (d.charAt(f + 1).charCodeAt(0) - 48) * 10 + (d.charAt(f + 2).charCodeAt(0) - 48);
                    x = d.charAt(f + 3).charCodeAt(0) - 48;
                    if (m < 0 || m >= 81 || x < 0 || x > 9)
                        r = -1;
                    else {
                        if (!s.$ && s.nb) {
                            M.da();
                            s.$ = -1
                        }
                        M.fa(m, x, 0);
                        f += 4
                    }
                }
                break;
            case "T":
                if (h - f < 4)
                    r = -1;
                else {
                    m = d.charAt(f + 1);
                    if (m == "<")
                        m = ">";
                    else if (m == "[")
                        m = "]";
                    else if (m == "{")
                        m = "}";
                    else if (m == "(")
                        m = ")";
                    j = R.nc(d.substring(f + 2), m);
                    if (j < 0)
                        j = h - f - 2;
                    a && n.Md(d.substring(f + 2, f + j + 2));
                    f += j + 3
                }
                break;
            case "W":
                if (h - f < 4)
                    r = -1;
                else {
                    m = d.charAt(f + 1);
                    if (m == "<")
                        m = ">";
                    else if (m == "[")
                        m = "]";
                    else if (m == "{")
                        m = "}";
                    else if (m == "(")
                        m = ")";
                    j = R.nc(d.substring(2), m);
                    if (!(j < 0)) {
                        z = 0;
                        Q.Wa(d.substring(f + 2, f + j + 2));
                        f = h
                    }
                }
                break;
            case "X":
                if (h - f < 2)
                    r = -1;
                else {
                    if (s.S > s.Xb && !M.s) {
                        j = d.charAt(f + 1).charCodeAt(0) - 48;
                        if (j == 0)
                            j = 5;
                        else
                            j *= 10;
                        M.v += j;
                        M.N += j
                    }
                    f += 2
                }
                break;
            case "Z":
                for (m = 0; m < 81; ++m)
                    s.p[0][m] = 0;
                ++f;
                break;
            case "z":
                for (m = 0; m < 81; ++m)
                    M.c[m] >= 0 && M.fa(m, 0, 0);
                for (m = 0; m < 81; ++m)
                    M.c[m] = -16384;
                ++f;
                break;
            default:
                r = -1
            }
        if (r) {
            j = h - f;
            if (j > 60)
                j = 60;
            b.a = "Invalid hint code (";
            for (m = 0; m < j; ++m)
                b.a += d.charAt(f + m);
            b.a += ")";
            b.a += "!";
            Q.Wa(b.a);
            M.h = -1;
            z = 0
        }
        if (z) {
            if (s.S > s.Xb)
                s.Xb = s.S;
            if (v)
                s.ma = 0;
            n.A(15, s.S > 1 || s.Yb >= 0 ? 0 : 3);
            n.Wd(15, s.Yb >= 0 ? "Learn" : "Back");
            n.Lc(-1)
        } else
            s.Cb();
        n.f(-1);
        s.$ && s.na()
    }
}
;
s.bc = function() {
    var a;
    if (M.h) {
        if (I.P)
            M.$a();
        else
            for (a = 0; a < 81; ++a)
                if (M.c[a] >= 0) {
                    if ((M.c[a] & 512) == 0)
                        M.c[a] &= -512
                } else
                    M.c[a] = -16384;
        n.f(-1)
    }
}
;
s.Ka = function() {
    var a, b;
    for (a = 0; a < 10; ++a) {
        b = a + 1 == s.g && s.j == 1 ? 1 : a < 9 && M.R[a] >= 9 && s.V != 1 ? 2 : 0;
        n.A(a, b)
    }
    n.A(10, s.ea ? 1 : I.ha == 1 && s.j == 2 && s.V != 1 ? 2 : 0)
}
;
s.gc = function() {
    var a = {};
    a.a = "";
    var b = {};
    b.a = "";
    var d;
    if (M.t.a.length < 81) {
        b.a = "";
        for (d = 0; d < 81; ++d)
            b.a += M.c[d] >= 0 ? ((M.c[d] >> 11 & 15) + 1).toString() : "."
    } else
        b.a = typeof M.t == "string" ? M.t : M.t.a;
    if (R.jb(b, 0, 0) != 1)
        Q.Wa("This is not a valid Sudoku puzzle.");
    else {
        M.T = 0;
        R.jb(b, a, 0);
        M.v += 600;
        M.N += 600;
        for (d = 0; d < 81; ++d)
            M.c[d] >= 0 && (M.c[d] & 512) == 0 && a.a.charAt(d).charCodeAt(0) - 48 - 1 != (M.c[d] >> 11 & 15) && M.fa(d, 0, 0);
        for (d = 0; d < 81; ++d)
            if (M.c[d] >= 0) {
                if ((M.c[d] & 512) == 0) {
                    b = a.a.charAt(d).charCodeAt(0) - 48 - 1;
                    if (b != (M.c[d] >> 11 & 15)) {
                        M.fa(d, 0, 0);
                        M.c[d] = 1 << b | -16384
                    }
                }
            } else {
                b = a.a.charAt(d).charCodeAt(0) - 48 - 1;
                b = 1 << b;
                if ((M.c[d] & 511) != b)
                    M.c[d] = b | -16384
            }
        n.f(-1);
        s.Ka()
    }
}
;
s.na = function() {
    n.A(12, M.k > 0 ? 0 : 3)
}
;
s.Id = function() {
    var a;
    if (s.wb)
        for (a = s.wb = 0; a < 81; ++a)
            s.p[1][a] = 0
}
;
s.Nc = function() {
    var a, b;
    if (!s.wb) {
        ++s.Wb;
        s.wb = -1;
        if (I.ia && s.j != 2)
            if (s.g == 10)
                for (b = 0; b < 81; ++b)
                    if (M.c[b] >= 0) {
                        if ((M.c[b] & 512) == 0)
                            s.p[1][b] = 7
                    } else {
                        if ((M.c[b] & 511) != M.bb(b))
                            s.p[1][b] = 7
                    }
            else {
                a = 1 << s.g - 1;
                for (b = 0; b < 81; ++b)
                    if (M.c[b] >= 0) {
                        if (1 << (M.c[b] >> 11 & 15) == a)
                            s.p[1][b] = 6
                    } else if ((M.c[b] & 511 & a) != 0)
                        s.p[1][b] = 7
            }
        s.ma = 1;
        n.f(-1);
        Q.ed(s.Wb)
    }
}
;
s.zb = function(a) {
    var b;
    if (I.ra) {
        s.Nc();
        for (b = 0; b < 9; ++b)
            s.p[1][o.cells[a][b]] = 8
    }
}
;
s.Zc = function(a) {
    var b;
    if (I.ra) {
        s.Nc();
        for (b = 0; b < 81; ++b)
            if (M.c[b] >= 0 && (M.c[b] >> 11 & 15) == a)
                s.p[1][b] = 8
    }
}
;
s.Yc = function(a) {
    if (s.Wb == a && s.ma == 1) {
        s.ma = s.V == 1 ? 2 : -1;
        n.f(-1)
    }
}
;
s.$c = function(a) {
    var b, d, f, h, j;
    b = M.v;
    if (b < 1)
        b = 1;
    d = M.N;
    if (d > b)
        d = b - 30;
    if (d < 0)
        d = 0;
    f = M.la * M.rb[p.d > 0 ? p.d : 0];
    if (f < 0)
        f = 0;
    if (f > d)
        f = d;
    j = d > 0;
    if (I.va > 0) {
        a.a = "nT'Your time: ";
        a.a += Math.floor(b / 60).toString();
        a.a += ":";
        h = b % 60;
        if (h < 10)
            a.a += "0";
        a.a += h.toString();
        if (d > 0) {
            a.a += " (";
            a.a += Math.floor((b - d) / 60).toString();
            a.a += ":";
            h = (b - d) % 60;
            if (h < 10)
                a.a += "0";
            a.a += h.toString();
            d -= f;
            if (d > 0) {
                a.a += " + ";
                a.a += Math.floor(d / 60).toString();
                a.a += ":";
                h = d % 60;
                if (h < 10)
                    a.a += "0";
                a.a += h.toString();
                a.a += " for hints"
            }
            if (f > 0) {
                a.a += " + ";
                a.a += Math.floor(f / 60).toString();
                a.a += ":";
                h = f % 60;
                if (h < 10)
                    a.a += "0";
                a.a += h.toString();
                a.a += " for mark incorrect"
            }
            a.a += ")"
        }
        h = 0;
        if (p.d < 12 && b >= 22 && h >= 0) {
            a.a += ", is faster than ";
            a.a += h.toString();
            a.a += "% of people ";
            a.a += M.T ? "not using help of any kind" : j ? typeof (M.J ? "using autopencil and hints" : "using hints and not autopencil") == "string" ? M.J ? "using autopencil and hints" : "using hints and not autopencil" : M.J ? "using autopencil and hints" : "using hints and not autopencil".a : typeof (M.J ? "using autopencil and not hints" : "not using autopencil or hints") == "string" ? M.J ? "using autopencil and not hints" : "not using autopencil or hints" : M.J ? "using autopencil and not hints" : "not using autopencil or hints".a
        }
        a.a += ".'"
    } else
        a.a = "nT'Game complete.'"
}
;
s.Hb = function(a) {
    var b = {};
    b.a = "";
    switch (a) {
    case 0:
        b.a = typeof M.e == "string" ? M.e : M.e.a;
        M.Ja(M.t.a);
        M.e.a = typeof b == "string" ? b : b.a;
        break;
    case 1:
        p.ic();
        Q.Ra();
        break;
    case 2:
        M.xa(p.n[0], 0);
        p.O[0] = Q.Fb();
        M.h = M.s = 0;
        p.q = 0;
        Q.Ra();
        break;
    case 3:
        Q.Ra();
        break;
    case 4:
        M.Dd();
        p.q = 6;
        break;
    case 5:
        M.xa(M.Q, 0);
        break;
    case 6:
        M.Xd();
        break;
    case 7:
        Q.ib(7, "Rotate and Mirror", 0);
        break;
    case 8:
        M.xa(p.n[0], 0);
        p.O[0] = Q.Fb();
        break;
    case 9:
        for (a = 0; a < 81; ++a)
            if (M.c[a] >= 0) {
                if ((M.c[a] & 512) == 0)
                    M.c[a] &= -512
            } else
                M.c[a] = -16384;
        n.f(-1);
        break;
    case 10:
        Q.ib(8, "", "")
    }
}
;
s.Bb = function(a, b) {
    switch (a) {
    case 2:
        if (b == 0) {
            s.gc();
            s.Cb()
        }
        break;
    case 3:
    case 4:
        if (b >= -5 && b < 0) {
            b = -b - 1;
            M.xa(p.n[b], 0);
            p.O[b] = Q.Fb();
            if (a == 4) {
                M.h = M.s = 0;
                p.q = 0;
                Q.Ra()
            }
        }
        break;
    case 5:
        s.Hb(-b - 1);
        break;
    case 6:
        switch (b) {
        case -1:
            s.md();
            break;
        case -2:
            s.hd();
            break;
        case -3:
            s.jd()
        }
        break;
    case 7:
        b < 0 && M.Ld(6 + b)
    }
}
;
var M = {};
M.h = 0;
M.c = Array(81);
M.ua = Array(9);
M.qa = Array(9);
M.pa = Array(9);
M.R = Array(9);
M.t = {};
M.t.a = "";
M.Z = {};
M.Z.a = "";
M.e = {};
M.e.a = "";
M.k = 0;
M.Fa = Array(64);
for (i = 0; i < 64; ++i)
    M.Fa[i] = Array(81);
M.Q = Array(182);
M.Y = Array(182);
M.rb = [0, 0, 5, 10, 20, 30, 60, 120, 180, 0, 0, 0, 10, 0, 0, 0];
M.Ta = function(a) {
    return M.c[a] >= 0
}
;
M.pc = function(a) {
    return (M.c[a] & 512) != 0
}
;
M.yd = function(a) {
    return (M.c[a] & 1024) != 0
}
;
M.Jb = function(a) {
    return M.c[a] & 511
}
;
M.ud = function(a) {
    return M.c[a] >> 11 & 15
}
;
M.cb = function(a) {
    return 1 << (M.c[a] >> 11 & 15)
}
;
M.Ob = function(a, b) {
    M.c[a] = b | -16384
}
;
M.Gb = function() {
    var a;
    for (a = 0; a < 81; ++a)
        M.c[a] = -16384;
    M.t.a = "";
    M.Z.a = "";
    M.e.a = "";
    M.J = 0;
    M.Q[0] = 0;
    M.Y[0] = 0
}
;
M.Qa = function() {
    var a, b;
    for (a = 0; a < 9; ++a) {
        M.ua[a] = 0;
        M.qa[a] = 0;
        M.pa[a] = 0
    }
    for (a = 0; a < 81; ++a)
        if (M.c[a] >= 0) {
            b = 1 << (M.c[a] >> 11 & 15);
            M.ua[o.b[0][a]] |= b;
            M.qa[o.b[1][a]] |= b;
            M.pa[o.b[2][a]] |= b
        }
}
;
M.$a = function() {
    var a;
    M.J = -1;
    M.Qa();
    for (a = 0; a < 81; ++a)
        M.c[a] >= 0 || (M.c[a] = (M.ua[o.b[0][a]] | M.qa[o.b[1][a]] | M.pa[o.b[2][a]]) ^ 511 | -16384)
}
;
M.jc = function() {
    var a = {};
    a.a = "";
    if (M.Z.a.length < 1)
        M.Z.a = M.s || o.Mc(M.t, a, 0) != 1 ? "X" : typeof a == "string" ? a : a.a
}
;
M.cc = function() {
    var a, b;
    for (a = 0; a < 81; ++a) {
        M.c[a] = -16384;
        for (b = 0; b < 3; ++b)
            s.p[b][a] = 0;
        s.pb[a] = 0
    }
    s.ma = s.V == 1 ? 2 : -1;
    M.t.a = "";
    M.Z.a = "";
    M.Pa = 0;
    for (a = s.vb = 0; a < 9; ++a) {
        M.R[a] = 0;
        M.ua[a] = 0;
        M.qa[a] = 0;
        M.pa[a] = 0
    }
    M.e.a = "W0";
    M.h = -1;
    M.s = -1;
    M.J = 0;
    M.T = !(I.ia || I.Ba || I.ra);
    M.la = 0
}
;
M.rc = function(a) {
    var b, d;
    M.cc();
    if (a.length == 81) {
        M.t.a = typeof a == "string" ? a : a.a;
        M.Z.a = "";
        for (b = M.s = 0; b < 81; ++b) {
            d = a.charAt(b);
            if (d == "." || d == "0" || d == "*" || d == "-")
                M.c[b] = -16384;
            else {
                d = d.charCodeAt(0) - 48 - 1;
                M.c[b] = d << 11 | 512;
                M.Pa += 1;
                M.R[d] += 1
            }
        }
    } else {
        M.t.a = "";
        M.Z.a = ""
    }
    M.Qa();
    I.P && M.$a();
    n.f(-1);
    s.Ka();
    M.v = M.N = 0
}
;
M.Ja = function(a) {
    var b;
    s.g = 1;
    s.m = 0;
    s.j = I.ha;
    s.ea = 0;
    for (b = s.V = 0; b < 81; ++b)
        s.p[2][b] = 0;
    M.k = 0;
    s.na();
    M.Q[0] = 0;
    M.rc(a);
    if (s.j == 2) {
        for (; s.m < 81 && M.c[s.m] >= 0; )
            ++s.m;
        if (s.m >= 81)
            s.m = 0
    }
}
;
M.bb = function(a) {
    return I.P ? (M.ua[o.b[0][a]] | M.qa[o.b[1][a]] | M.pa[o.b[2][a]]) ^ 511 : 0
}
;
M.cd = function(a, b) {
    var d, f, h;
    if (I.wa == 1) {
        f = o.qb[a];
        for (d = 0; d < 20; ++d) {
            h = f[d];
            if (M.c[h] >= 0 && (M.cb(h) & b) != 0)
                return
        }
        M.c[a] &= -1025;
        n.f(a)
    }
}
;
M.fa = function(a, b, d) {
    var f, h, j, q;
    if (M.c[a] >= 0) {
        if ((M.c[a] & 512) != 0)
            return;
        q = (M.c[a] >> 11 & 15) + 1
    } else
        q = 0;
    if (b > 0) {
        M.Pa += 1;
        M.R[b - 1] += 1;
        f = 1 << b - 1;
        if (d)
            M.c[a] = b - 1 << 11 | 512;
        else {
            M.c[a] = b - 1 << 11 | M.c[a] & 511;
            if (I.wa == 2) {
                M.jc();
                if (M.Z.a.length > 1 && M.Z.a.charAt(a) != b.toString()) {
                    M.c[a] |= 1024;
                    h = o.qb[a];
                    for (d = 0; d < 20; ++d) {
                        j = h[d];
                        if (M.c[j] >= 0 && M.cb(j) == f)
                            break
                    }
                    if (d >= 20) {
                        M.v += M.rb[p.d > 0 ? p.d : 0];
                        M.N += M.rb[p.d > 0 ? p.d : 0];
                        ++M.la
                    }
                }
            }
        }
        h = o.qb[a];
        for (d = 0; d < 20; ++d) {
            j = h[d];
            if (M.c[j] >= 0) {
                if (I.wa == 1 && M.cb(j) == f) {
                    M.c[a] |= 1024;
                    if ((M.c[j] & 512) == 0)
                        M.c[j] |= 1024;
                    n.f(j)
                }
            } else if (I.Ba || I.P) {
                M.c[j] &= ~f;
                n.f(j)
            }
        }
        s.Id();
        M.R[b - 1] == 9 && s.Zc(b - 1);
        if ((M.ua[o.b[0][a]] |= f) == 511)
            s.zb(0 + o.b[0][a]);
        if ((M.qa[o.b[1][a]] |= f) == 511)
            s.zb(9 + o.b[1][a]);
        if ((M.pa[o.b[2][a]] |= f) == 511)
            s.zb(18 + o.b[2][a]);
        n.f(a)
    } else
        M.c[a] |= -16384;
    q > 0 && M.Qa();
    if (b <= 0) {
        if (I.P || b < 0)
            M.c[a] = M.bb(a) | -16384;
        n.f(a)
    }
    if (q > 0) {
        M.Pa -= 1;
        b = q - 1;
        M.R[b] -= 1;
        M.R[b] == 8 && s.g == 10 && s.Ka();
        f = 1 << b;
        h = o.qb[a];
        for (d = 0; d < 20; ++d) {
            j = h[d];
            if (M.c[j] >= 0)
                (M.c[j] >> 11 & 15) == b && M.cd(j, f);
            else if (I.P && (~(M.ua[o.b[0][j]] | M.qa[o.b[1][j]] | M.pa[o.b[2][j]]) & f) != 0) {
                M.c[j] |= f;
                n.f(j)
            }
        }
    }
}
;
M.bc = function() {
    var a;
    if (M.h) {
        if (I.P)
            CalcPencil();
        else
            for (a = 0; a < 81; ++a)
                M.c[a] >= 0 || (M.c[a] = -16384);
        n.f(-1)
    }
}
;
M.pd = function(a) {
    var b;
    a.a = "";
    for (b = 0; b < 81; ++b)
        a.a += M.c[b] >= 0 ? ((M.c[b] >> 11 & 15) + 1).toString() : "."
}
;
M.Dd = function() {
    var a;
    M.t.a = "";
    for (a = 0; a < 81; ++a)
        if (M.c[a] >= 0) {
            M.c[a] |= 512;
            M.t.a += ((M.c[a] >> 11 & 15) + 1).toString()
        } else
            M.t.a += ".";
    M.Z.a = "";
    M.k = 0;
    s.na();
    n.f(-1);
    M.e.a = "U0";
    M.s = 0;
    M.J = I.P;
    M.T = !(I.ia || I.Ba || I.ra);
    M.la = 0
}
;
M.wc = function() {
    var a, b = Array(9), d = Array(9), f = Array(9), h, j, q, m, u, x, z;
    for (j = z = 0; j < 81; ++j)
        if (M.c[j] >= 0 && (M.c[j] & 1024) != 0) {
            M.c[j] &= -1025;
            z = -1
        }
    if (!M.s) {
        switch (I.wa) {
        case 1:
            for (h = 0; h < 9; ++h) {
                b[h] = 0;
                d[h] = 0;
                f[h] = 0
            }
            for (h = 0; h < 81; ++h)
                if (M.c[h] >= 0) {
                    q = o.b[0][h];
                    m = o.b[1][h];
                    u = o.b[2][h];
                    a = 1 << (M.c[h] >> 11 & 15);
                    if ((b[q] & a) != 0)
                        for (x = 0; x < 9; ++x) {
                            j = q * 9 + x;
                            if (M.c[j] >= 0 && (M.c[j] & 512) == 0 && 1 << (M.c[j] >> 11 & 15) == a) {
                                M.c[j] |= 1024;
                                z = -1
                            }
                        }
                    b[q] |= a;
                    if ((d[m] & a) != 0)
                        for (x = 0; x < 9; ++x) {
                            j = x * 9 + m;
                            if (M.c[j] >= 0 && (M.c[j] & 512) == 0 && 1 << (M.c[j] >> 11 & 15) == a) {
                                M.c[j] |= 1024;
                                z = -1
                            }
                        }
                    d[m] |= a;
                    if ((f[u] & a) != 0)
                        for (x = 0; x < 9; ++x) {
                            j = o.cells[18 + u][x];
                            if (M.c[j] >= 0 && (M.c[j] & 512) == 0 && 1 << (M.c[j] >> 11 & 15) == a) {
                                M.c[j] |= 1024;
                                z = -1
                            }
                        }
                    f[u] |= a
                }
            break;
        case 2:
            M.jc();
            if (M.Z.a.charAt(0) != "X")
                for (h = 0; h < 81; ++h)
                    if (M.c[h] >= 0)
                        if ((M.c[h] >> 11 & 15) != M.Z.a.charAt(h).charCodeAt(0) - 48 - 1) {
                            M.c[h] |= 1024;
                            z = -1
                        }
        }
        z && n.f(-1)
    }
}
;
M.Ua = function(a, b, d) {
    var f, h;
    if (b >= 0 && d == 182) {
        M.cc();
        M.s = 0;
        M.t.a = "";
        if (a[b++] == 1) {
            for (h = 0; h < 81; ++h) {
                d = (a[b] << 7) + a[b + 1];
                b += 2;
                M.c[h] = d & 511 | -16384;
                d >>= 9;
                if (d > 18)
                    d = 0;
                f = ".";
                if (d >= 10) {
                    M.c[h] = d - 10 << 11 | 512;
                    M.R[d - 10] += 1;
                    ++M.Pa;
                    f = String.fromCharCode("1".charCodeAt(0) + (d - 10))
                } else if (d > 0) {
                    M.c[h] = d - 1 << 11 | M.c[h] & 511;
                    M.R[d - 1] += 1;
                    ++M.Pa
                }
                M.t.a += f
            }
            M.v = (a[b] << 14) + (a[b + 1] << 7) + a[b + 2];
            b += 3;
            M.N = (a[b] << 14) + (a[b + 1] << 7) + a[b + 2];
            b += 3;
            if (a[b] == 1) {
                M.J = -1;
                M.T = 0
            } else if (a[b] == 2)
                M.T = 0;
            ++b;
            M.la = (a[b] << 7) + a[b + 1];
            b += 2;
            M.e.a = "";
            M.e.a += a[b] >= 0 && a[b] < 12 || a[b] >= 20 && a[b] < 26 ? String.fromCharCode("A".charCodeAt(0) + a[b]) : "A";
            ++b;
            a = (a[b] << 14) + (a[b + 1] << 7) + a[b + 2];
            M.e.a += a.toString()
        }
        if (M.e.a.charAt(0) == "W") {
            M.s = -1;
            M.t.a = ""
        }
        p.Wc();
        M.Qa();
        M.wc();
        s.Ka();
        n.f(-1);
        s.Ga()
    }
    return 182
}
;
M.sc = function(a, b, d) {
    var f;
    s.g = 1;
    s.m = 0;
    s.j = I.ha;
    s.ea = 0;
    for (f = s.V = 0; f < 81; ++f)
        s.p[2][f] = 0;
    M.k = 0;
    s.na();
    M.Q[0] = 0;
    a = M.Ua(a, b, d);
    if (s.j == 2) {
        for (; s.m < 81 && M.c[s.m] >= 0; )
            ++s.m;
        if (s.m >= 81)
            s.m = 0
    }
    return a
}
;
M.xa = function(a, b) {
    var d, f, h;
    if (b >= 0)
        if (M.h) {
            f = b;
            a[b++] = 1;
            for (h = 0; h < 81; ++h) {
                d = M.c[h] & 511;
                if (M.c[h] >= 0)
                    d += (M.c[h] & 512) != 0 ? (M.c[h] >> 11 & 15) + 10 << 9 : (M.c[h] >> 11 & 15) + 1 << 9;
                a[b++] = d >> 7 & 127;
                a[b++] = d & 127
            }
            d = M.v >= 6E5 ? 599999 : M.v;
            a[b++] = d >> 14 & 127;
            a[b++] = d >> 7 & 127;
            a[b++] = d & 127;
            d = M.N >= 6E5 ? 599999 : M.N;
            a[b++] = d >> 14 & 127;
            a[b++] = d >> 7 & 127;
            a[b++] = d & 127;
            if (M.J)
                a[b++] = 1;
            else if (M.T)
                a[b++] = 0;
            else
                a[b++] = 2;
            if (M.la >= 4096)
                M.la = 4095;
            a[b++] = M.la >> 7 & 127;
            a[b++] = M.la & 127;
            if (M.e.a.length > 1) {
                a[b++] = M.e.a.charAt(0).charCodeAt(0) - "A".charCodeAt(0);
                d = parseInt(M.e.a.substring(1))
            } else
                d = a[b++] = 0;
            a[b++] = d >> 14 & 127;
            a[b++] = d >> 7 & 127;
            for (a[b++] = d & 127; b - f < 182; )
                a[b++] = 0
        } else
            a[b] = 0;
    return 182
}
;
M.qd = function(a) {
    var b, d;
    a.a = "";
    for (b = 0; b < 81; ++b) {
        d = M.c[b] >= 0 ? 1 << (M.c[b] >> 11 & 15) | M.c[b] & 1536 : M.c[b] & 511 | -512;
        a.a += R.Vb.charAt(d >> 6 & 63);
        a.a += R.Vb.charAt(d & 63)
    }
}
;
M.da = function() {
    var a;
    if (M.k >= 64) {
        --M.k;
        for (a = 0; a < M.k; ++a)
            M.Fa[a] = M.Fa[a + 1]
    }
    M.Fa[M.k] = M.c.slice(0);
    ++M.k;
    s.mb()
}
;
M.Db = function(a) {
    var b = Array(182);
    M.c = M.Fa[a].slice(0);
    a = M.h;
    M.h = -1;
    M.xa(b, 0);
    M.Ua(b, 0, 182);
    M.h = a
}
;
M.Ld = function(a) {
    var b = Array(81), d = Array(81), f = Array(81), h, j;
    if (M.s)
        for (h = 0; h < 81; ++h)
            d[h] = 0;
    else
        for (h = 0; h < 81; ++h) {
            j = M.t.a.charAt(h);
            d[h] = j == "." || j == "0" || j == "*" || j == "-" ? 0 : j.charCodeAt(0) - 48
        }
    for (h = 0; h < 81; ++h) {
        switch (a) {
        case 0:
            j = o.b[1][h] * 9 + (8 - o.b[0][h]);
            break;
        case 1:
            j = (8 - o.b[0][h]) * 9 + (8 - o.b[1][h]);
            break;
        case 2:
            j = (8 - o.b[1][h]) * 9 + o.b[0][h];
            break;
        case 3:
            j = (8 - o.b[0][h]) * 9 + o.b[1][h];
            break;
        case 4:
            j = o.b[0][h] * 9 + (8 - o.b[1][h]);
            break;
        case 5:
            j = (8 - o.b[1][h]) * 9 + (8 - o.b[0][h]);
            break;
        case 6:
            j = o.b[1][h] * 9 + o.b[0][h];
            break;
        default:
            j = h
        }
        b[j] = M.c[h];
        f[j] = d[h]
    }
    if (!M.s) {
        M.t.a = "";
        for (h = 0; h < 81; ++h)
            M.t.a += f[h] != 0 ? f[h].toString() : "."
    }
    M.c = b.slice(0);
    M.Z.a = "";
    M.Qa();
    n.f(-1)
}
;
M.Xd = function() {
    var a, b;
    M.da();
    s.na();
    a = M.v;
    b = M.N;
    M.Ua(M.Q, 0, 182);
    M.v = a;
    M.N = b;
    s.Ga()
}
;
var I = {};
I.ia = -1;
I.va = 2;
I.ta = 0;
I.ra = -1;
I.ne = 0;
I.Za = 0;
I.P = 0;
I.Ba = -1;
I.wa = 1;
I.Aa = 0;
I.Da = 1;
I.ba = 0;
I.ha = 0;
I.me = 0;
I.Rc = 0;
I.Sc = 0;
I.Ic = function(a, b) {
    if (I.ia != a) {
        I.ia = a;
        if (!b) {
            Q.B();
            if (M.h) {
                if (a)
                    M.T = 0;
                n.f(-1)
            }
        }
    }
}
;
I.Pb = function(a, b) {
    if (a < 0 || a > 2)
        a = 2;
    if (I.va != a) {
        I.va = a;
        if (!b) {
            Q.B();
            M.h && s.Ga()
        }
    }
}
;
I.Hc = function(a, b) {
    if (I.ta != a) {
        I.ta = a;
        b || Q.B()
    }
}
;
I.Ec = function(a, b) {
    if (I.ra != a) {
        I.ra = a;
        b || Q.B()
    }
}
;
I.Gc = function(a, b) {
    if (I.Za != a) {
        I.Za = a;
        b || Q.B()
    }
}
;
I.Mb = function(a, b) {
    var d;
    if (a < 0 || a > 2)
        a = 0;
    d = I.P ? 2 : I.Ba ? 1 : 0;
    if (d != a) {
        I.P = a == 2;
        I.Ba = a == 1;
        if (!b) {
            Q.B();
            if (M.h) {
                I.P != (d == 2) && s.bc();
                if (a == 1)
                    M.T = 0
            }
        }
    }
}
;
I.Jc = function(a, b) {
    if (a < 0 || a > 2)
        a = 0;
    if (I.wa != a) {
        I.wa = a;
        if (!b) {
            Q.B();
            M.h && M.wc()
        }
    }
}
;
I.Fc = function(a, b) {
    if (a < 0 || a > 2)
        a = 0;
    if (I.ha != a) {
        I.ha = a;
        if (!b) {
            Q.B();
            if (M.h && a != 0)
                s.j = a
        }
    }
}
;
I.Cc = function(a, b) {
    if (a < 0 || a > 4)
        a = 0;
    if (I.Aa != a) {
        I.Aa = a;
        if (!b) {
            Q.B();
            if (M.h) {
                Q.vc();
                n.f(-1)
            }
        }
    }
}
;
I.Ob = function(a, b) {
    if (a < 0 || a > 3)
        a = 1;
    if (I.Da != a) {
        I.Da = a;
        if (!b) {
            Q.B();
            M.h && n.f(-1)
        }
    }
}
;
I.Ac = function(a, b) {
    if (a < 0 || a > 5)
        a = 0;
    if (I.ba != a) {
        I.ba = a;
        if (!b) {
            Q.B();
            M.h && n.f(-1)
        }
    }
}
;
I.je = function(a, b) {
    if (I.Rc != a) {
        I.Rc = a;
        b || Q.B()
    }
}
;
I.ke = function(a, b) {
    if (I.Sc != a) {
        I.Sc = a;
        b || Q.B()
    }
}
;
var P = {};
P.F = Array(80);
P.G = Array(80);
P.r = Array(80);
P.I = Array(80);
P.w = Array(80);
P.C = Array(80);
P.lc = function(a, b, d, f) {
    if (a < -3)
        return -1;
    if (a > 12)
        a = 15;
    else
        a += 3;
    if (f)
        b = 4;
    else {
        b = b ? 1 : 0;
        if (d)
            b += 2
    }
    return a * 5 + b
}
;
P.xc = function() {
    var a;
    for (a = 0; a < 80; ++a) {
        P.F[a] = 0;
        P.G[a] = 0;
        P.r[a] = 0;
        P.I[a] = 0;
        P.w[a] = 6E4;
        P.C[a] = 0
    }
}
;
P.Ed = function(a, b, d, f) {
    a = P.lc(a, b, d, f);
    if (a >= 0)
        P.F[a] += 1
}
;
P.Fd = function(a, b, d, f, h) {
    b = P.lc(a, b, d, f);
    if (!(b < 0 || h < 22 && a >= 0 && a < 12)) {
        if (h > 59999)
            h = 59999;
        else if (h < 1)
            h = 1;
        P.G[b] += 1;
        P.r[b] = P.r[b] > 0 ? h + Math.floor((11 * P.r[b] + 6) / 12) : P.r[b] < 0 ? (h - P.r[b]) * 6 : -h;
        if (P.w[b] > h)
            P.w[b] = h;
        if (P.C[b] < h)
            P.C[b] = h;
        P.I[b] += h
    }
}
;
P.dd = function(a, b) {
    var d, f;
    b.a = "";
    f = 0;
    if (a >= 1E6) {
        d = Math.floor(a / 1E6);
        b.a += d.toString();
        b.a += ",";
        a -= d * 1E6;
        f = -1
    }
    if (a > 1E3 || f) {
        d = Math.floor(a / 1E3);
        if (f)
            if (d < 10)
                b.a += "00";
            else if (d < 100)
                b.a += "0";
        b.a += d.toString();
        b.a += ",";
        a -= d * 1E3;
        f = -1
    }
    if (f)
        if (a < 10)
            b.a += "00";
        else if (a < 100)
            b.a += "0";
    b.a += a.toString()
}
;
P.Ub = function(a, b) {
    var d;
    b.a = "";
    if (a >= 0 && a <= 59999) {
        b.a += Math.floor(a / 60).toString();
        b.a += ":";
        d = a % 60;
        if (d < 10)
            b.a += "0";
        b.a += d.toString()
    }
}
;
P.Xc = function(a, b) {
    var d;
    if (a < 1)
        return 0;
    d = b;
    d += Math.floor(a / 2);
    return Math.floor(d / a)
}
;
P.Kb = function(a, b, d, f, h, j) {
    j.a = "";
    if (a >= 0 && a < 15 && h > 0 && h <= 59999) {
        j.a += "&nbsp;";
        j.a += (0).toString();
        j.a += "%"
    }
}
;
P.ad = function(a) {
    var b = {};
    b.a = "";
    var d, f, h, j, q, m, u, x, z;
    f = h = j = d = 0;
    z = 6E4;
    for (q = u = x = 0; q < 80; ++q) {
        f += P.F[q];
        h += P.G[q];
        if (P.r[q] > 0) {
            j += P.r[q];
            ++u
        } else if (P.r[q] < 0) {
            j += -12 * P.r[q];
            ++u
        }
        d += P.I[q];
        if (z > P.w[q])
            z = P.w[q];
        if (x < P.C[q])
            x = P.C[q]
    }
    if (u > 1)
        j = Math.floor(j / u);
    a.a += '<TABLE class="stats" style="padding: 10px;" width="100%">\n';
    for (q = -1; q < 80; ++q) {
        u = Math.floor(q / 5);
        x = q % 5;
        if (q >= 0) {
            f = P.F[q];
            h = P.G[q];
            j = P.r[q];
            d = P.I[q];
            z = P.w[q]
        }
        if (!(q >= 0 && h == 0)) {
            if (q >= 0)
                a.a += "<tr><td colspan=5></td></tr>\n";
            a.a += "<tr><td colspan=5><b>";
            a.a += q < 0 ? "Over All" : typeof p.W[u + 3] == "string" ? p.W[u + 3] : p.W[u + 3].a;
            a.a += "</b>";
            if (q < 0)
                u = -1;
            else
                a.a += x == 0 ? " - (no pencil or hints)" : x == 1 ? " - (autopencil)" : x == 2 ? " - (hints)" : x == 3 ? " - (autopencil & hints)" : " - (pure, no help)";
            a.a += "</td></tr>\n";
            if (f == 0)
                m = 100;
            else {
                m = h + f;
                m = Math.floor((h * 100 + Math.floor(m / 2)) / m);
                if (m < 0)
                    m = 0;
                if (m >= 100)
                    m = 99
            }
            a.a += "<tr><td>&nbsp; &nbsp;</td><td>Games Completed</td><td>&nbsp; &nbsp;</td><td align=right>";
            P.dd(h, b);
            a.a += typeof b == "string" ? b : b.a;
            a.a += "</td><td align=right>";
            a.a += m.toString();
            a.a += "%</td></tr>\n";
            if (h <= 0 || z < 0 || z > 59999)
                a.a += "<tr><td></td><td>Fastest Time</td><td></td><td colspan=2 align=right>never&nbsp;played</td></tr>\n";
            else {
                a.a += "<tr><td></td><td>Fastest Time</td><td></td><td align=right>";
                P.Ub(z, b);
                a.a += typeof b == "string" ? b : b.a;
                a.a += "</td><td align=right>";
                P.Kb(u, x & 1, x & 2, x & 4, z, b);
                a.a += typeof b == "string" ? b : b.a;
                a.a += "</td></tr>\n"
            }
            if (j != 0) {
                m = j > 0 ? Math.floor((j + 6) / 12) : -1 * j;
                a.a += "<tr><td></td><td>Recent Average</td><td></td><td align=right>";
                P.Ub(m, b);
                a.a += typeof b == "string" ? b : b.a;
                a.a += "</td><td align=right>";
                P.Kb(u, x & 1, x & 2, x & 4, m, b);
                a.a += typeof b == "string" ? b : b.a;
                a.a += "</td></tr>\n"
            }
            if (h > 0) {
                a.a += "<tr><td></td><td>Average Time</td><td></td><td align=right>";
                m = P.Xc(h, d);
                P.Ub(m, b);
                a.a += typeof b == "string" ? b : b.a;
                a.a += "</td><td align=right>";
                P.Kb(u, x & 1, x & 2, x & 4, m, b);
                a.a += typeof b == "string" ? b : b.a;
                a.a += "</td></tr>\n"
            }
            a.a += "<tr><td>&nbsp;</td></tr>\n"
        }
    }
    a.a += "</table>\n"
}
;
var o = {};
o.Td = 9;
o.le = 511;
o.X = [-1, 0, 1, -1, 2, -1, -1, -1, 3, -1, -1, -1, -1, -1, -1, -1, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
o.b = [[0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8], [0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8], [0, 0, 0, 1, 1, 1, 2, 2, 2, 0, 0, 0, 1, 1, 1, 2, 2, 2, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 3, 3, 3, 4, 4, 4, 5, 5, 5, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 8, 6, 6, 6, 7, 7, 7, 8, 8, 8, 6, 6, 6, 7, 7, 7, 8, 8, 8]];
o.u = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8], [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8], [0, 1, 2, 0, 1, 2, 0, 1, 2, 3, 4, 5, 3, 4, 5, 3, 4, 5, 6, 7, 8, 6, 7, 8, 6, 7, 8, 0, 1, 2, 0, 1, 2, 0, 1, 2, 3, 4, 5, 3, 4, 5, 3, 4, 5, 6, 7, 8, 6, 7, 8, 6, 7, 8, 0, 1, 2, 0, 1, 2, 0, 1, 2, 3, 4, 5, 3, 4, 5, 3, 4, 5, 6, 7, 8, 6, 7, 8, 6, 7, 8]];
o.cells = [[0, 1, 2, 3, 4, 5, 6, 7, 8], [9, 10, 11, 12, 13, 14, 15, 16, 17], [18, 19, 20, 21, 22, 23, 24, 25, 26], [27, 28, 29, 30, 31, 32, 33, 34, 35], [36, 37, 38, 39, 40, 41, 42, 43, 44], [45, 46, 47, 48, 49, 50, 51, 52, 53], [54, 55, 56, 57, 58, 59, 60, 61, 62], [63, 64, 65, 66, 67, 68, 69, 70, 71], [72, 73, 74, 75, 76, 77, 78, 79, 80], [0, 9, 18, 27, 36, 45, 54, 63, 72], [1, 10, 19, 28, 37, 46, 55, 64, 73], [2, 11, 20, 29, 38, 47, 56, 65, 74], [3, 12, 21, 30, 39, 48, 57, 66, 75], [4, 13, 22, 31, 40, 49, 58, 67, 76], [5, 14, 23, 32, 41, 50, 59, 68, 77], [6, 15, 24, 33, 42, 51, 60, 69, 78], [7, 16, 25, 34, 43, 52, 61, 70, 79], [8, 17, 26, 35, 44, 53, 62, 71, 80], [0, 1, 2, 9, 10, 11, 18, 19, 20], [3, 4, 5, 12, 13, 14, 21, 22, 23], [6, 7, 8, 15, 16, 17, 24, 25, 26], [27, 28, 29, 36, 37, 38, 45, 46, 47], [30, 31, 32, 39, 40, 41, 48, 49, 50], [33, 34, 35, 42, 43, 44, 51, 52, 53], [54, 55, 56, 63, 64, 65, 72, 73, 74], [57, 58, 59, 66, 67, 68, 75, 76, 77], [60, 61, 62, 69, 70, 71, 78, 79, 80]];
o.ga = [0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8, 4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8, 5, 6, 6, 7, 6, 7, 7, 8, 6, 7, 7, 8, 7, 8, 8, 9];
o.Ca = [0, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 16, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 32, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 16, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 64, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 16, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 32, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 16, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 128, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 16, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 32, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 16, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 64, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 16, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 32, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 16, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 256, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 16, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 32, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 16, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 64, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 16, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 32, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 16, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 128, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 16, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 32, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 16, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 64, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 16, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 32, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1, 16, 1, 2, 1, 4, 1, 2, 1, 8, 1, 2, 1, 4, 1, 2, 1];
o.qb = [[9, 18, 27, 36, 45, 54, 63, 72, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 19, 20], [10, 19, 28, 37, 46, 55, 64, 73, 0, 2, 3, 4, 5, 6, 7, 8, 9, 11, 18, 20], [11, 20, 29, 38, 47, 56, 65, 74, 0, 1, 3, 4, 5, 6, 7, 8, 9, 10, 18, 19], [12, 21, 30, 39, 48, 57, 66, 75, 0, 1, 2, 4, 5, 6, 7, 8, 13, 14, 22, 23], [13, 22, 31, 40, 49, 58, 67, 76, 0, 1, 2, 3, 5, 6, 7, 8, 12, 14, 21, 23], [14, 23, 32, 41, 50, 59, 68, 77, 0, 1, 2, 3, 4, 6, 7, 8, 12, 13, 21, 22], [15, 24, 33, 42, 51, 60, 69, 78, 0, 1, 2, 3, 4, 5, 7, 8, 16, 17, 25, 26], [16, 25, 34, 43, 52, 61, 70, 79, 0, 1, 2, 3, 4, 5, 6, 8, 15, 17, 24, 26], [17, 26, 35, 44, 53, 62, 71, 80, 0, 1, 2, 3, 4, 5, 6, 7, 15, 16, 24, 25], [0, 18, 27, 36, 45, 54, 63, 72, 10, 11, 12, 13, 14, 15, 16, 17, 1, 2, 19, 20], [1, 19, 28, 37, 46, 55, 64, 73, 9, 11, 12, 13, 14, 15, 16, 17, 0, 2, 18, 20], [2, 20, 29, 38, 47, 56, 65, 74, 9, 10, 12, 13, 14, 15, 16, 17, 0, 1, 18, 19], [3, 21, 30, 39, 48, 57, 66, 75, 9, 10, 11, 13, 14, 15, 16, 17, 4, 5, 22, 23], [4, 22, 31, 40, 49, 58, 67, 76, 9, 10, 11, 12, 14, 15, 16, 17, 3, 5, 21, 23], [5, 23, 32, 41, 50, 59, 68, 77, 9, 10, 11, 12, 13, 15, 16, 17, 3, 4, 21, 22], [6, 24, 33, 42, 51, 60, 69, 78, 9, 10, 11, 12, 13, 14, 16, 17, 7, 8, 25, 26], [7, 25, 34, 43, 52, 61, 70, 79, 9, 10, 11, 12, 13, 14, 15, 17, 6, 8, 24, 26], [8, 26, 35, 44, 53, 62, 71, 80, 9, 10, 11, 12, 13, 14, 15, 16, 6, 7, 24, 25], [0, 9, 27, 36, 45, 54, 63, 72, 19, 20, 21, 22, 23, 24, 25, 26, 1, 2, 10, 11], [1, 10, 28, 37, 46, 55, 64, 73, 18, 20, 21, 22, 23, 24, 25, 26, 0, 2, 9, 11], [2, 11, 29, 38, 47, 56, 65, 74, 18, 19, 21, 22, 23, 24, 25, 26, 0, 1, 9, 10], [3, 12, 30, 39, 48, 57, 66, 75, 18, 19, 20, 22, 23, 24, 25, 26, 4, 5, 13, 14], [4, 13, 31, 40, 49, 58, 67, 76, 18, 19, 20, 21, 23, 24, 25, 26, 3, 5, 12, 14], [5, 14, 32, 41, 50, 59, 68, 77, 18, 19, 20, 21, 22, 24, 25, 26, 3, 4, 12, 13], [6, 15, 33, 42, 51, 60, 69, 78, 18, 19, 20, 21, 22, 23, 25, 26, 7, 8, 16, 17], [7, 16, 34, 43, 52, 61, 70, 79, 18, 19, 20, 21, 22, 23, 24, 26, 6, 8, 15, 17], [8, 17, 35, 44, 53, 62, 71, 80, 18, 19, 20, 21, 22, 23, 24, 25, 6, 7, 15, 16], [0, 9, 18, 36, 45, 54, 63, 72, 28, 29, 30, 31, 32, 33, 34, 35, 37, 38, 46, 47], [1, 10, 19, 37, 46, 55, 64, 73, 27, 29, 30, 31, 32, 33, 34, 35, 36, 38, 45, 47], [2, 11, 20, 38, 47, 56, 65, 74, 27, 28, 30, 31, 32, 33, 34, 35, 36, 37, 45, 46], [3, 12, 21, 39, 48, 57, 66, 75, 27, 28, 29, 31, 32, 33, 34, 35, 40, 41, 49, 50], [4, 13, 22, 40, 49, 58, 67, 76, 27, 28, 29, 30, 32, 33, 34, 35, 39, 41, 48, 50], [5, 14, 23, 41, 50, 59, 68, 77, 27, 28, 29, 30, 31, 33, 34, 35, 39, 40, 48, 49], [6, 15, 24, 42, 51, 60, 69, 78, 27, 28, 29, 30, 31, 32, 34, 35, 43, 44, 52, 53], [7, 16, 25, 43, 52, 61, 70, 79, 27, 28, 29, 30, 31, 32, 33, 35, 42, 44, 51, 53], [8, 17, 26, 44, 53, 62, 71, 80, 27, 28, 29, 30, 31, 32, 33, 34, 42, 43, 51, 52], [0, 9, 18, 27, 45, 54, 63, 72, 37, 38, 39, 40, 41, 42, 43, 44, 28, 29, 46, 47], [1, 10, 19, 28, 46, 55, 64, 73, 36, 38, 39, 40, 41, 42, 43, 44, 27, 29, 45, 47], [2, 11, 20, 29, 47, 56, 65, 74, 36, 37, 39, 40, 41, 42, 43, 44, 27, 28, 45, 46], [3, 12, 21, 30, 48, 57, 66, 75, 36, 37, 38, 40, 41, 42, 43, 44, 31, 32, 49, 50], [4, 13, 22, 31, 49, 58, 67, 76, 36, 37, 38, 39, 41, 42, 43, 44, 30, 32, 48, 50], [5, 14, 23, 32, 50, 59, 68, 77, 36, 37, 38, 39, 40, 42, 43, 44, 30, 31, 48, 49], [6, 15, 24, 33, 51, 60, 69, 78, 36, 37, 38, 39, 40, 41, 43, 44, 34, 35, 52, 53], [7, 16, 25, 34, 52, 61, 70, 79, 36, 37, 38, 39, 40, 41, 42, 44, 33, 35, 51, 53], [8, 17, 26, 35, 53, 62, 71, 80, 36, 37, 38, 39, 40, 41, 42, 43, 33, 34, 51, 52], [0, 9, 18, 27, 36, 54, 63, 72, 46, 47, 48, 49, 50, 51, 52, 53, 28, 29, 37, 38], [1, 10, 19, 28, 37, 55, 64, 73, 45, 47, 48, 49, 50, 51, 52, 53, 27, 29, 36, 38], [2, 11, 20, 29, 38, 56, 65, 74, 45, 46, 48, 49, 50, 51, 52, 53, 27, 28, 36, 37], [3, 12, 21, 30, 39, 57, 66, 75, 45, 46, 47, 49, 50, 51, 52, 53, 31, 32, 40, 41], [4, 13, 22, 31, 40, 58, 67, 76, 45, 46, 47, 48, 50, 51, 52, 53, 30, 32, 39, 41], [5, 14, 23, 32, 41, 59, 68, 77, 45, 46, 47, 48, 49, 51, 52, 53, 30, 31, 39, 40], [6, 15, 24, 33, 42, 60, 69, 78, 45, 46, 47, 48, 49, 50, 52, 53, 34, 35, 43, 44], [7, 16, 25, 34, 43, 61, 70, 79, 45, 46, 47, 48, 49, 50, 51, 53, 33, 35, 42, 44], [8, 17, 26, 35, 44, 62, 71, 80, 45, 46, 47, 48, 49, 50, 51, 52, 33, 34, 42, 43], [0, 9, 18, 27, 36, 45, 63, 72, 55, 56, 57, 58, 59, 60, 61, 62, 64, 65, 73, 74], [1, 10, 19, 28, 37, 46, 64, 73, 54, 56, 57, 58, 59, 60, 61, 62, 63, 65, 72, 74], [2, 11, 20, 29, 38, 47, 65, 74, 54, 55, 57, 58, 59, 60, 61, 62, 63, 64, 72, 73], [3, 12, 21, 30, 39, 48, 66, 75, 54, 55, 56, 58, 59, 60, 61, 62, 67, 68, 76, 77], [4, 13, 22, 31, 40, 49, 67, 76, 54, 55, 56, 57, 59, 60, 61, 62, 66, 68, 75, 77], [5, 14, 23, 32, 41, 50, 68, 77, 54, 55, 56, 57, 58, 60, 61, 62, 66, 67, 75, 76], [6, 15, 24, 33, 42, 51, 69, 78, 54, 55, 56, 57, 58, 59, 61, 62, 70, 71, 79, 80], [7, 16, 25, 34, 43, 52, 70, 79, 54, 55, 56, 57, 58, 59, 60, 62, 69, 71, 78, 80], [8, 17, 26, 35, 44, 53, 71, 80, 54, 55, 56, 57, 58, 59, 60, 61, 69, 70, 78, 79], [0, 9, 18, 27, 36, 45, 54, 72, 64, 65, 66, 67, 68, 69, 70, 71, 55, 56, 73, 74], [1, 10, 19, 28, 37, 46, 55, 73, 63, 65, 66, 67, 68, 69, 70, 71, 54, 56, 72, 74], [2, 11, 20, 29, 38, 47, 56, 74, 63, 64, 66, 67, 68, 69, 70, 71, 54, 55, 72, 73], [3, 12, 21, 30, 39, 48, 57, 75, 63, 64, 65, 67, 68, 69, 70, 71, 58, 59, 76, 77], [4, 13, 22, 31, 40, 49, 58, 76, 63, 64, 65, 66, 68, 69, 70, 71, 57, 59, 75, 77], [5, 14, 23, 32, 41, 50, 59, 77, 63, 64, 65, 66, 67, 69, 70, 71, 57, 58, 75, 76], [6, 15, 24, 33, 42, 51, 60, 78, 63, 64, 65, 66, 67, 68, 70, 71, 61, 62, 79, 80], [7, 16, 25, 34, 43, 52, 61, 79, 63, 64, 65, 66, 67, 68, 69, 71, 60, 62, 78, 80], [8, 17, 26, 35, 44, 53, 62, 80, 63, 64, 65, 66, 67, 68, 69, 70, 60, 61, 78, 79], [0, 9, 18, 27, 36, 45, 54, 63, 73, 74, 75, 76, 77, 78, 79, 80, 55, 56, 64, 65], [1, 10, 19, 28, 37, 46, 55, 64, 72, 74, 75, 76, 77, 78, 79, 80, 54, 56, 63, 65], [2, 11, 20, 29, 38, 47, 56, 65, 72, 73, 75, 76, 77, 78, 79, 80, 54, 55, 63, 64], [3, 12, 21, 30, 39, 48, 57, 66, 72, 73, 74, 76, 77, 78, 79, 80, 58, 59, 67, 68], [4, 13, 22, 31, 40, 49, 58, 67, 72, 73, 74, 75, 77, 78, 79, 80, 57, 59, 66, 68], [5, 14, 23, 32, 41, 50, 59, 68, 72, 73, 74, 75, 76, 78, 79, 80, 57, 58, 66, 67], [6, 15, 24, 33, 42, 51, 60, 69, 72, 73, 74, 75, 76, 77, 79, 80, 61, 62, 70, 71], [7, 16, 25, 34, 43, 52, 61, 70, 72, 73, 74, 75, 76, 77, 78, 80, 60, 62, 69, 71], [8, 17, 26, 35, 44, 53, 62, 71, 72, 73, 74, 75, 76, 77, 78, 79, 60, 61, 69, 70]];
o.Tb = function(a) {
    return o.b[0][a]
}
;
o.Sb = function(a) {
    return o.b[1][a]
}
;
o.Sd = function(a) {
    return o.b[2][a]
}
;
o.Xa = function(a, b) {
    return a * 9 + b
}
;
o.Pc = function(a) {
    return o.ga[a]
}
;
o.Vd = function(a) {
    return o.X[a]
}
;
o.Ud = function(a) {
    return o.Ca[a]
}
;
o.Mc = function(a, b, d) {
    var f = Array(27), h = Array(27), j = Array(27), q = Array(81), m = Array(81), u = Array(81), x, z, r, t, v, C, y, G, O, K, B, V, J;
    if (a.a.length != 81)
        return 0;
    for (r = 0; r < 27; ++r) {
        f[r] = 511;
        h[r] = 0
    }
    for (B = z = x = 0; B < 81; ++B) {
        q[B] = 0;
        t = a.a.charAt(B);
        if (t == "." || t == "0" || t == "*" || t == "-")
            u[z++] = B;
        else {
            t = t.charCodeAt(0) - 48 - 1;
            m[B] = t;
            C = 1 << t;
            if ((h[v = o.b[0][B]] & C) != 0)
                return 0;
            h[v] |= C;
            f[v] ^= 1 << o.u[0][B];
            if ((h[v = o.b[1][B] + 9] & C) != 0)
                return 0;
            h[v] |= C;
            f[v] ^= 1 << o.u[1][B];
            if ((h[v = o.b[2][B] + 18] & C) != 0)
                return 0;
            h[v] |= C;
            f[v] ^= 1 << o.u[2][B]
        }
    }
    for (J = a = t = 0; d || t < 2; ) {
        for (; x < z || J; ) {
            if (x >= a) {
                do {
                    v = 10;
                    for (r = x; r < z; ++r) {
                        B = u[r];
                        C = ((h[o.b[0][B]] | h[o.b[1][B] + 9] | h[o.b[2][B] + 18]) ^ 511) & ~q[B];
                        if ((C = o.ga[C]) != 0)
                            if (C < v) {
                                a = x;
                                v = C;
                                C = u[a];
                                u[a] = B;
                                u[r] = C;
                                ++a
                            } else {
                                if (C == 1) {
                                    C = u[a];
                                    u[a] = B;
                                    u[r] = C;
                                    ++a
                                }
                            }
                        else {
                            a = x;
                            J = -1;
                            break
                        }
                    }
                    V = 0;
                    if (v > 1 && !J) {
                        for (r = 0; r < 27; ++r) {
                            G = O = 0;
                            for (K = f[r]; K != 0; ) {
                                y = o.Ca[K];
                                K ^= y;
                                v = o.X[y];
                                B = o.cells[r][v];
                                C = ((h[o.b[0][B]] | h[o.b[1][B] + 9] | h[o.b[2][B] + 18]) ^ 511) & ~q[B];
                                O |= G & C;
                                G |= C
                            }
                            if ((G | h[r]) != 511) {
                                J = -1;
                                break
                            } else
                                j[r] = G & ~O
                        }
                        if (!J)
                            for (r = x; r < z; ++r) {
                                B = u[r];
                                C = ((h[o.b[0][B]] | h[o.b[1][B] + 9] | h[o.b[2][B] + 18]) ^ 511) & ~q[B];
                                if ((y = C & j[o.b[0][B]]) != 0 || (y = C & j[o.b[1][B] + 9]) != 0 || (y = C & j[o.b[2][B] + 18]) != 0)
                                    if (o.ga[y] != 1)
                                        J = -1;
                                    else {
                                        m[B] = o.X[y];
                                        h[v = o.b[0][B]] |= y;
                                        f[v] ^= 1 << o.u[0][B];
                                        h[v = o.b[1][B] + 9] |= y;
                                        f[v] ^= 1 << o.u[1][B];
                                        h[v = o.b[2][B] + 18] |= y;
                                        f[v] ^= 1 << o.u[2][B];
                                        q[B] = 511;
                                        C = u[x];
                                        u[x++] = u[r];
                                        u[r] = C;
                                        V = -1
                                    }
                            }
                        if (V) {
                            a = x;
                            if (x >= z)
                                break
                        }
                    }
                } while (V)
            }
            if (J)
                C = 0;
            else {
                B = u[x];
                C = ((h[o.b[0][B]] | h[o.b[1][B] + 9] | h[o.b[2][B] + 18]) ^ 511) & ~q[B];
                C = o.Ca[C]
            }
            if (C != 0) {
                m[B] = o.X[C];
                h[v = o.b[0][B]] |= C;
                f[v] ^= 1 << o.u[0][B];
                h[v = o.b[1][B] + 9] |= C;
                f[v] ^= 1 << o.u[1][B];
                h[v = o.b[2][B] + 18] |= C;
                f[v] ^= 1 << o.u[2][B];
                ++x;
                if (a < x)
                    a = x;
                q[B] |= C
            } else
                for (J = 0; ; ) {
                    if (x <= 0)
                        return t;
                    B = u[--x];
                    y = 1 << m[B];
                    C = ((h[o.b[0][B]] | h[o.b[1][B] + 9] | h[o.b[2][B] + 18]) ^ 511) & ~q[B];
                    C = o.Ca[C];
                    if (C != 0) {
                        m[B] = o.X[C];
                        y |= C;
                        h[o.b[0][B]] ^= y;
                        h[o.b[1][B] + 9] ^= y;
                        h[o.b[2][B] + 18] ^= y;
                        q[B] |= C;
                        ++x;
                        a = x;
                        break
                    } else {
                        h[v = o.b[0][B]] ^= y;
                        f[v] ^= 1 << o.u[0][B];
                        h[v = o.b[1][B] + 9] ^= y;
                        f[v] ^= 1 << o.u[1][B];
                        h[v = o.b[2][B] + 18] ^= y;
                        f[v] ^= 1 << o.u[2][B];
                        q[B] = 0
                    }
                }
        }
        ++t;
        if (t == 1 && b != 0) {
            b.a = "";
            for (v = 0; v < 81; ++v)
                b.a += (m[v] + 1).toString()
        }
        if (d || t < 2)
            J = -1
    }
    return t
}
;
var R = {};
R.Vb = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_$";
R.D = function(a) {
    return Math.floor(Math.random() * a)
}
;
R.yc = function(a) {
    var b, d;
    b = o.ga[a];
    if (b == 0)
        return 0;
    for (b = R.D(b); ; ) {
        d = o.Ca[a];
        if (--b < 0)
            return d;
        a ^= d
    }
}
;
R.jb = function(a, b, d) {
    var f = Array(27), h = Array(27), j = Array(27), q = Array(81), m = Array(81), u = Array(81), x, z, r, t, v, C, y, G, O, K, B, V, J;
    for (r = 0; r < 27; ++r) {
        f[r] = 511;
        h[r] = 0
    }
    for (t = z = x = 0; t < 81; ++t) {
        q[t] = 0;
        C = a.a.charAt(t);
        if (C == "." || C == "0" || C == "*" || C == "-")
            u[z++] = t;
        else {
            C = C.charCodeAt(0) - 48 - 1;
            m[t] = C;
            v = 1 << C;
            if ((h[y = o.b[0][t]] & v) != 0)
                return 0;
            h[y] |= v;
            f[y] ^= 1 << o.b[1][t];
            if ((h[y = o.b[1][t] + 9] & v) != 0)
                return 0;
            h[y] |= v;
            f[y] ^= 1 << o.b[0][t];
            if ((h[y = o.b[2][t] + 9 + 9] & v) != 0)
                return 0;
            h[y] |= v;
            f[y] ^= 1 << o.u[2][t]
        }
    }
    for (J = a = C = 0; d || C < 2; ) {
        for (; x < z || J; ) {
            if (x >= a) {
                do {
                    y = 10;
                    for (r = x; r < z; ++r) {
                        t = u[r];
                        v = ((h[o.b[0][t]] | h[o.b[1][t] + 9] | h[o.b[2][t] + 9 + 9]) ^ 511) & ~q[t];
                        if ((v = o.ga[v]) != 0)
                            if (v < y) {
                                a = x;
                                y = v;
                                v = u[a];
                                u[a] = t;
                                u[r] = v;
                                ++a
                            } else {
                                if (v == 1) {
                                    v = u[a];
                                    u[a] = t;
                                    u[r] = v;
                                    ++a
                                }
                            }
                        else {
                            a = x;
                            J = -1;
                            break
                        }
                    }
                    V = 0;
                    if (y > 1 && !J) {
                        for (r = 0; r < 27; ++r) {
                            O = K = 0;
                            for (B = f[r]; B != 0; ) {
                                G = o.Ca[B];
                                B ^= G;
                                y = o.X[G];
                                t = o.cells[r][y];
                                v = ((h[o.b[0][t]] | h[o.b[1][t] + 9] | h[o.b[2][t] + 9 + 9]) ^ 511) & ~q[t];
                                K |= O & v;
                                O |= v
                            }
                            if ((O | h[r]) != 511) {
                                J = -1;
                                break
                            } else
                                j[r] = O & ~K
                        }
                        if (!J)
                            for (r = x; r < z; ++r) {
                                t = u[r];
                                v = ((h[o.b[0][t]] | h[o.b[1][t] + 9] | h[o.b[2][t] + 9 + 9]) ^ 511) & ~q[t];
                                if ((G = v & j[o.b[0][t]]) != 0 || (G = v & j[o.b[1][t] + 9]) != 0 || (G = v & j[o.b[2][t] + 9 + 9]) != 0)
                                    if (o.ga[G] != 1)
                                        J = -1;
                                    else {
                                        m[t] = o.X[G];
                                        h[y = o.b[0][t]] |= G;
                                        f[y] ^= 1 << o.b[1][t];
                                        h[y = o.b[1][t] + 9] |= G;
                                        f[y] ^= 1 << o.b[0][t];
                                        h[y = o.b[2][t] + 9 + 9] |= G;
                                        f[y] ^= 1 << o.u[2][t];
                                        q[t] = 511;
                                        v = u[x];
                                        u[x++] = u[r];
                                        u[r] = v;
                                        V = -1
                                    }
                            }
                        if (V) {
                            a = x;
                            if (x >= z)
                                break
                        }
                    }
                } while (V)
            }
            if (J)
                v = 0;
            else {
                t = u[x];
                v = ((h[o.b[0][t]] | h[o.b[1][t] + 9] | h[o.b[2][t] + 9 + 9]) ^ 511) & ~q[t];
                v = R.yc(v)
            }
            if (v != 0) {
                m[t] = o.X[v];
                h[y = o.b[0][t]] |= v;
                f[y] ^= 1 << o.b[1][t];
                h[y = o.b[1][t] + 9] |= v;
                f[y] ^= 1 << o.b[0][t];
                h[y = o.b[2][t] + 9 + 9] |= v;
                f[y] ^= 1 << o.u[2][t];
                ++x;
                if (a < x)
                    a = x;
                q[t] |= v
            } else
                for (J = 0; ; ) {
                    if (x <= 0)
                        return C;
                    t = u[--x];
                    G = 1 << m[t];
                    v = ((h[o.b[0][t]] | h[o.b[1][t] + 9] | h[o.b[2][t] + 9 + 9]) ^ 511) & ~q[t];
                    if (v != 0) {
                        v = R.yc(v);
                        m[t] = o.X[v];
                        G |= v;
                        h[o.b[0][t]] ^= G;
                        h[o.b[1][t] + 9] ^= G;
                        h[o.b[2][t] + 9 + 9] ^= G;
                        q[t] |= v;
                        ++x;
                        a = x;
                        break
                    } else {
                        h[y = o.b[0][t]] ^= G;
                        f[y] ^= 1 << o.b[1][t];
                        h[y = o.b[1][t] + 9] ^= G;
                        f[y] ^= 1 << o.b[0][t];
                        h[y = o.b[2][t] + 9 + 9] ^= G;
                        f[y] ^= 1 << o.u[2][t];
                        q[t] = 0
                    }
                }
        }
        ++C;
        if (C == 1 && b != 0) {
            b.a = "";
            for (y = 0; y < 81; ++y)
                b.a += (m[y] + 1).toString()
        }
        if (d || C < 2)
            J = -1
    }
    return C
}
;
R.Oc = function(a, b, d) {
    var f = Array(27), h = Array(27), j = Array(27), q = Array(81), m = Array(81), u, x, z, r, t, v, C, y, G, O, K;
    for (v = 0; v < 27; ++v) {
        f[v] = 511;
        h[v] = 0
    }
    for (r = x = u = 0; r < 81; ++r) {
        v = a.a.charAt(r);
        if (v == "." || v == "0" || v == "*" || v == "-")
            m[x++] = r;
        else {
            v = v.charCodeAt(0) - 48 - 1;
            q[r] = v;
            y = 1 << v;
            if ((h[t = o.b[0][r]] & y) != 0)
                return 0;
            h[t] |= y;
            f[t] ^= 1 << o.b[1][r];
            if ((h[t = o.b[1][r] + 9] & y) != 0)
                return 0;
            h[t] |= y;
            f[t] ^= 1 << o.b[0][r];
            if ((h[t = o.b[2][r] + 9 + 9] & y) != 0)
                return 0;
            h[t] |= y;
            f[t] ^= 1 << o.u[2][r]
        }
    }
    for (a = C = 0; u < x; ) {
        ++C;
        K = 0;
        if (!K)
            for (v = 0; v < 27; ++v)
                if (o.ga[f[v]] == 1) {
                    K = -1;
                    r = o.cells[v][o.X[f[v]]];
                    for (z = u; m[z] != r; ++z)
                        ;
                    if (z >= a) {
                        t = m[a];
                        m[a] = r;
                        m[z] = t;
                        ++a
                    }
                }
        if (b && !K) {
            for (v = 18; v < 27; ++v) {
                z = G = 0;
                for (O = f[v]; O != 0; ) {
                    y = o.Ca[O];
                    O ^= y;
                    t = o.X[y];
                    r = o.cells[v][t];
                    y = (h[o.b[0][r]] | h[o.b[1][r] + 9] | h[o.b[2][r] + 9 + 9]) ^ 511;
                    G |= z & y;
                    z |= y
                }
                if ((z | h[v]) != 511)
                    return 99999;
                else
                    j[v] = z & ~G
            }
            for (z = u; z < x; ++z) {
                r = m[z];
                y = (h[o.b[0][r]] | h[o.b[1][r] + 9] | h[o.b[2][r] + 9 + 9]) ^ 511;
                if ((y = y & j[o.b[2][r] + 9 + 9]) != 0)
                    if (o.ga[y] != 1)
                        return 99999;
                    else {
                        K = -1;
                        q[r] = o.X[y];
                        h[t = o.b[0][r]] |= y;
                        f[t] ^= 1 << o.b[1][r];
                        h[t = o.b[1][r] + 9] |= y;
                        f[t] ^= 1 << o.b[0][r];
                        h[t = o.b[2][r] + 9 + 9] |= y;
                        f[t] ^= 1 << o.u[2][r];
                        t = m[u];
                        m[u++] = m[z];
                        m[z] = t;
                        if (a < u)
                            a = u
                    }
            }
        }
        if (d && !K)
            for (z = u; z < x; ++z) {
                r = m[z];
                y = (h[o.b[0][r]] | h[o.b[1][r] + 9] | h[o.b[2][r] + 9 + 9]) ^ 511;
                if ((v = o.ga[y]) != 0) {
                    if (v == 1) {
                        K = -1;
                        t = m[a];
                        m[a] = r;
                        m[z] = t;
                        ++a
                    }
                } else
                    return 99999
            }
        for (; u < a; ) {
            r = m[u];
            y = (h[o.b[0][r]] | h[o.b[1][r] + 9] | h[o.b[2][r] + 9 + 9]) ^ 511;
            if (o.ga[y] != 1)
                return 88888;
            q[r] = o.X[y];
            h[t = o.b[0][r]] |= y;
            f[t] ^= 1 << o.b[1][r];
            h[t = o.b[1][r] + 9] |= y;
            f[t] ^= 1 << o.b[0][r];
            h[t = o.b[2][r] + 9 + 9] |= y;
            f[t] ^= 1 << o.u[2][r];
            ++u
        }
        if (!K)
            return 99999
    }
    return C
}
;
R.l = Array(81);
R.Bd = function(a) {
    var b, d;
    for (b = 0; b < 81; ++b) {
        d = a.a.charAt(b);
        R.l[b] = d == "." || d == "0" || d == "*" || d == "-" ? 0 : d.charCodeAt(0) - 48
    }
}
;
R.eb = function(a) {
    var b;
    a.a = "";
    for (b = 0; b < 81; ++b)
        a.a += R.l[b] != 0 ? R.l[b].toString() : "."
}
;
R.aa = function(a, b, d) {
    var f;
    switch (d) {
    case 0:
        for (f = 0; f < 9; ++f) {
            d = R.l[a * 9 + f];
            R.l[a * 9 + f] = R.l[b * 9 + f];
            R.l[b * 9 + f] = d
        }
        break;
    case 1:
        for (f = 0; f < 9; ++f) {
            d = R.l[f * 9 + a];
            R.l[f * 9 + a] = R.l[f * 9 + b];
            R.l[f * 9 + b] = d
        }
        break;
    case 2:
        a *= 3;
        b *= 3;
        R.aa(a, b, 0);
        R.aa(a + 1, b + 1, 0);
        R.aa(a + 2, b + 2, 0);
        break;
    case 3:
        a *= 3;
        b *= 3;
        R.aa(a, b, 1);
        R.aa(a + 1, b + 1, 1);
        R.aa(a + 2, b + 2, 1)
    }
}
;
R.Ha = function(a, b, d) {
    (b & 1) != 0 && R.aa(a, a + 1, d);
    (b & 2) != 0 && R.aa(a + 1, a + 2, d);
    (b & 4) != 0 && R.aa(a, a + 2, d)
}
;
R.dc = function(a, b, d) {
    (b & 1) != 0 && R.aa(a + 1, a + 2, d);
    (b & 2) != 0 && R.aa(a, a + 1, d);
    (b & 4) != 0 && R.aa(a, a + 2, d)
}
;
R.ie = function(a, b) {
    var d = Array(9), f, h, j, q;
    for (h = 0; h < 9; ++h)
        d[h] = h + 1;
    for (h = 0; h < 8; ++h) {
        j = R.D(9 - h) + h;
        f = d[h];
        d[h] = d[j];
        d[j] = f
    }
    for (h = 0; h < 81; ++h)
        R.l[h] = a.a.charAt(h) == "." ? 0 : d[a.a.charAt(h).charCodeAt(0) - 48 - 1];
    d = R.D(6);
    R.Ha(0, d, 0);
    R.Ha(3, R.D(2) * 4, 0);
    R.dc(6, d, 0);
    d = R.D(6);
    R.Ha(0, d, 1);
    R.Ha(3, R.D(2) * 4, 1);
    R.dc(6, d, 1);
    R.Ha(0, R.D(2) * 4, 2);
    R.Ha(0, R.D(2) * 4, 2);
    if (R.D(2) != 0)
        for (j = 0; j < 5; ++j)
            for (q = 0; q < 9; ++q) {
                if (q == 4 && j == 4)
                    break;
                h = j * 9 + q;
                d = (8 - o.b[0][h]) * 9 + (8 - o.b[1][h]);
                f = R.l[h];
                R.l[h] = R.l[d];
                R.l[d] = f
            }
    if (R.D(2) != 0)
        for (j = 0; j < 9; ++j)
            for (q = 0; q <= j; ++q) {
                f = R.l[j * 9 + q];
                R.l[j * 9 + q] = R.l[q * 9 + j];
                R.l[q * 9 + j] = f
            }
    R.eb(b)
}
;
R.nc = function(a, b) {
    return a.indexOf(b)
}
;
R.yb = function(a) {
    return R.Vb.indexOf(a)
}
;
R.Yd = function(a, b) {
    var d, f, h, j;
    b.a = "";
    f = a.length;
    for (d = 0; d < f; ++d) {
        h = R.yb(a.charAt(d));
        j = Math.floor(h / 10);
        h %= 10;
        for (b.a += h != 0 ? h.toString() : "."; --j >= 0; )
            b.a += "."
    }
}
;
R.td = function(a) {
    for (var b, d; ; ) {
        for (d = 0; d < 81; ++d)
            R.l[d] = 0;
        for (b = 0; b < 13; ++b) {
            d = R.D(81);
            R.l[d] = R.D(9) + 1
        }
        R.eb(a);
        if (R.jb(a, a, 0) >= 1)
            break
    }
}
;
R.sd = function(a, b) {
    var d, f, h, j;
    do {
        j = -1;
        R.td(b);
        R.Bd(b);
        switch (a) {
        case 0:
            f = R.D(81);
            R.l[f] = 0;
            break;
        case 1:
            d = R.D(18);
            for (h = 0; h < 9; ++h) {
                f = o.cells[d][h];
                R.l[f] = 0
            }
            break;
        case 2:
            d = 18 + R.D(9);
            for (h = 0; h < 9; ++h) {
                f = o.cells[d][h];
                R.l[f] = 0
            }
            break;
        case 3:
        case 4:
        case 5:
            for (d = 0; d < (a - 1) * 10; ++d) {
                do
                    f = R.D(81);
                while (R.l[f] == 0);
                R.l[f] = 0
            }
            R.eb(b);
            if (R.jb(b, 0, 0) != 1 || R.Oc(b, -1, 0) > 14 || R.Oc(b, 0, -1) > 14)
                j = 0
        }
    } while (!j);
    R.eb(b)
}
;
