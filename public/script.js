const form = document.getElementById("studentForm");
const message = document.getElementById("message");
const resultsList = document.getElementById("resultsList");
const refreshButton = document.getElementById("refreshButton");

function showMessage(text, type) {
  message.textContent = text;
  message.className = `message ${type}`;
}

function renderStudents(students) {
  if (!students.length) {
    resultsList.innerHTML = "<p>No submissions yet.</p>";
    return;
  }

  resultsList.innerHTML = students
    .slice()
    .reverse()
    .map(
      (student) => `
        <article class="result-item">
          <p><strong>Name:</strong> ${student.name}</p>
          <p><strong>Roll Number:</strong> ${student.rollNumber}</p>
          <p><strong>Marks:</strong> ${student.marks}</p>
          <p><strong>Submitted:</strong> ${new Date(student.submittedAt).toLocaleString()}</p>
        </article>
      `
    )
    .join("");
}

async function loadStudents() {
  try {
    const response = await fetch("/api/students");
    const students = await response.json();
    renderStudents(students);
  } catch (error) {
    showMessage("Unable to load submissions.", "error");
  }
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  const formData = new FormData(form);
  const payload = Object.fromEntries(formData.entries());

  showMessage("Submitting result and generating system load...", "success");

  try {
    const response = await fetch("/student", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(payload)
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || "Submission failed");
    }

    showMessage(data.message, "success");
    form.reset();
    loadStudents();
  } catch (error) {
    showMessage(error.message, "error");
  }
});

refreshButton.addEventListener("click", loadStudents);
loadStudents();
