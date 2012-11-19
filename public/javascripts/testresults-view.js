function switch_display(element) {
    e = document.getElementById(element)
    if (e.style.display == "none") {
        e.style.display = "block"
    } else {
        e.style.display = "none"
    }
}
