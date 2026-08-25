/* interactive-report page behaviour. Concatenated into every report inside <script>,
   AFTER the content, BEFORE the meta script and the comment layer.

   Two jobs, both opt-in from the content fragment:
     1. Fills an empty <nav class="toc"></nav> from the h2[id]/h3[id] in .wrap.
        A hand-written (non-empty) nav.toc is left alone.
     2. Renders window.QUIZ into the element with id "quiz". No #quiz or no
        window.QUIZ means no quiz; that is a normal report, not an error. */
(function () {
  var wrap = document.querySelector(".wrap") || document.body;

  /* ---------- table of contents ---------- */
  var nav = wrap.querySelector("nav.toc");
  if (nav && !nav.children.length) {
    var heads = Array.prototype.slice.call(wrap.querySelectorAll("h2[id], h3[id]"));
    if (heads.length) {
      var h4 = document.createElement("h4");
      h4.textContent = "Contents";
      var ol = document.createElement("ol");
      var lastTop = null;   /* the h2 <li> that h3 entries nest under */
      heads.forEach(function (h) {
        var li = document.createElement("li");
        var a = document.createElement("a");
        a.href = "#" + h.id;
        a.textContent = h.textContent;
        li.appendChild(a);
        if (h.tagName === "H3" && lastTop) {
          var sub = lastTop.querySelector("ol.sub");
          if (!sub) {
            sub = document.createElement("ol");
            sub.className = "sub";
            lastTop.appendChild(sub);
          }
          sub.appendChild(li);
        } else {
          ol.appendChild(li);
          lastTop = li;
        }
      });
      nav.appendChild(h4);
      nav.appendChild(ol);
    }
  }

  /* ---------- quiz ---------- */
  var host = document.getElementById("quiz");
  var QUESTIONS = window.QUIZ;
  if (!host || !QUESTIONS || !QUESTIONS.length) return;
  var MARKS = "ABCDEFGH";

  QUESTIONS.forEach(function (q, qi) {
    var el = document.createElement("div");
    el.className = "q";

    var stem = document.createElement("div");
    stem.className = "stem";
    stem.innerHTML =
      '<span class="n">Question ' + (qi + 1) + " of " + QUESTIONS.length + "</span>" + q.stem;
    el.appendChild(stem);

    var fb = document.createElement("div");
    fb.className = "fb";

    q.options.forEach(function (opt, oi) {
      var b = document.createElement("button");
      b.className = "opt";
      b.type = "button";
      b.innerHTML = '<span class="mark">' + MARKS[oi] + ".</span>" + opt;
      b.addEventListener("click", function () {
        var buttons = el.querySelectorAll(".opt");
        Array.prototype.forEach.call(buttons, function (x) { x.disabled = true; });
        var right = oi === q.answer;
        b.classList.add(right ? "correct" : "wrong");
        if (!right) buttons[q.answer].classList.add("correct");
        fb.className = "fb show " + (right ? "ok" : "no");
        fb.innerHTML =
          "<b>" + (right ? "Correct." : "Not quite.") + "</b> " + q.fb[oi] +
          (right
            ? ""
            : "<br><br><b>The answer is " + MARKS[q.answer] + ":</b> " + q.fb[q.answer]);
      });
      el.appendChild(b);
    });

    el.appendChild(fb);
    host.appendChild(el);
  });
})();
