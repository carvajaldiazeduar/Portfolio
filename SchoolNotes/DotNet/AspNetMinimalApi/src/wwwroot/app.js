const { createApp, ref, reactive, computed, onMounted } = Vue;

const ENTITIES = [
  { name: "students", label: "Students", fields: [
    { key: "firstName", label: "First Name", required: true },
    { key: "lastName", label: "Last Name", required: true },
    { key: "code", label: "Code", required: true },
    { key: "email", label: "Email" }
  ]},
  { name: "teachers", label: "Teachers", fields: [
    { key: "firstName", label: "First Name", required: true },
    { key: "lastName", label: "Last Name", required: true },
    { key: "code", label: "Code", required: true },
    { key: "email", label: "Email" }
  ]},
  { name: "courses", label: "Courses", fields: [
    { key: "name", label: "Name", required: true },
    { key: "teacherId", label: "Teacher", required: true, type: "fk", ref: "teachers" }
  ]},
  { name: "periods", label: "Periods", fields: [
    { key: "name", label: "Name", required: true }
  ]},
  { name: "enrollments", label: "Enrollments", fields: [
    { key: "studentId", label: "Student", required: true, type: "fk", ref: "students" },
    { key: "courseId", label: "Course", required: true, type: "fk", ref: "courses" },
    { key: "periodId", label: "Period", required: true, type: "fk", ref: "periods" }
  ]},
  { name: "grades", label: "Grades", fields: [
    { key: "enrollmentId", label: "Enrollment", required: true, type: "fk", ref: "enrollments" },
    { key: "label", label: "Label", required: true },
    { key: "score", label: "Score", required: true, number: true },
    { key: "maxScore", label: "Max", number: true },
    { key: "observation", label: "Observation" }
  ]}
];

async function api(method, url, body) {
  const res = await fetch(url, {
    method,
    credentials: "same-origin",
    headers: body ? { "Content-Type": "application/json" } : {},
    body: body ? JSON.stringify(body) : undefined
  });
  if (res.status === 401) return { unauthorized: true };
  const text = await res.text();
  let data = null;
  if (text) {
    try { data = JSON.parse(text); } catch { data = text; }
  }
  return { status: res.status, data };
}

const FIELD_ERROR_MESSAGES = {
  code: "A record with this code already exists. Please use a different one.",
  email: "Please enter a valid email address.",
  name: "Please enter a valid name.",
  firstName: "Please enter a valid first name.",
  lastName: "Please enter a valid last name.",
  label: "Please enter a valid label.",
  observation: "Please enter a valid observation.",
  score: "Please enter a valid score.",
  maxScore: "Please enter a valid maximum score.",
  teacherId: "Please choose a valid teacher.",
  studentId: "Please choose a valid student.",
  courseId: "Please choose a valid course.",
  periodId: "Please choose a valid period.",
  enrollmentId: "Please choose a valid enrollment."
};

function isTechnical(text) {
  return typeof text === "string" && /violation|exception|constraint|sqlstate|stack trace|unhandled/i.test(text);
}

function humanizeFieldErrors(errs) {
  const out = {};
  if (!errs || typeof errs !== "object") return out;
  Object.keys(errs).forEach(k => {
    const norm = k.charAt(0).toLowerCase() + k.slice(1);
    const serverMsg = errs[k];
    out[norm] = FIELD_ERROR_MESSAGES[norm] ||
      (typeof serverMsg === "string" && serverMsg.trim() && !isTechnical(serverMsg)
        ? serverMsg
        : "This field is invalid. Please check it and try again.");
  });
  return out;
}

function statusMessage(status) {
  switch (status) {
    case 400: return "Please correct the highlighted fields and try again.";
    case 401:
    case 403: return "You are not authorized. Please log in again.";
    case 404: return "The item you requested was not found.";
    case 409: return "This conflicts with existing data (for example, a duplicate code).";
    case 422: return "Some of the values you entered are not valid.";
    case 500: return "An unexpected error occurred. Please try again later.";
    default: return "Something went wrong. Please try again.";
  }
}

createApp({
  setup() {
    const authenticated = ref(false);
    const loginUser = ref("");
    const loginPass = ref("");
    const entities = ENTITIES;
    const active = ref("students");
    const items = ref([]);
    const page = ref(1);
    const pageSize = 4;
    const loading = ref(false);
    const toasts = ref([]);
    const showForm = ref(false);
    const editing = ref(null);
    const form = reactive({});
    const errors = ref({});
    const confirmDelete = reactive({ open: false, id: null });
    const options = reactive({});

    const fields = computed(() => entities.find(e => e.name === active.value).fields);

    function personName(item) {
      const n = `${item.firstName || ""} ${item.lastName || ""}`.trim();
      return n || item.code || `#${item.id}`;
    }

    function fkLabel(field, item) {
      if (!item) return "";
      if (field.ref === "enrollments") {
        const s = options.students ? options.students.find(x => x.id === item.studentId) : null;
        const c = options.courses ? options.courses.find(x => x.id === item.courseId) : null;
        const sName = s ? personName(s) : `Student ${item.studentId}`;
        const cName = c ? c.name : `Course ${item.courseId}`;
        return `${sName} · ${cName}`;
      }
      if (field.ref === "courses" || field.ref === "periods") return item.name || "";
      return personName(item);
    }

    function displayFk(field, id) {
      if (id === null || id === undefined || id === 0) return "—";
      const list = options[field.ref] || [];
      const item = list.find(x => x.id === id) || null;
      if (!item) {
        loadOptionsFor(field.ref, true);
        return "Loading...";
      }
      return fkLabel(field, item);
    }

    function fkPlaceholder(field) {
      const list = options[field.ref];
      if (!list || list.length === 0) return `No ${field.ref} available`;
      return `Select ${field.label}...`;
    }

    async function loadOptionsFor(refName) {
      delete options[refName];
      const r = await api("GET", `/api/${refName}?page=1&pageSize=200`);
      if (r.unauthorized) return [];
      const data = (r.data && Array.isArray(r.data)) ? r.data : [];
      options[refName] = data;
      return data;
    }

    async function ensureFkOptions() {
      const fks = fields.value.filter(f => f.type === "fk");
      for (const f of fks) {
        await loadOptionsFor(f.ref);
        if (f.ref === "enrollments") {
          await loadOptionsFor("students");
          await loadOptionsFor("courses");
        }
      }
    }

    function toast(message, type) {
      const id = Date.now() + Math.random();
      toasts.value.push({ id, message, type: type || "info" });
      setTimeout(() => { toasts.value = toasts.value.filter(t => t.id !== id); }, 3000);
    }

    async function load() {
      loading.value = true;
      const cfg = entities.find(e => e.name === active.value);
      await ensureFkOptions();
      const r = await api("GET", `/api/${cfg.name}?page=${page.value}&pageSize=${pageSize}`);
      if (r.unauthorized) { authenticated.value = false; loading.value = false; return; }
      items.value = r.data || [];
      loading.value = false;
    }

    async function selectEntity(name) {
      active.value = name;
      page.value = 1;
      items.value = [];
      await load();
    }

    async function doLogin() {
      const r = await api("POST", "/api/auth/login", { username: loginUser.value, password: loginPass.value });
      if (r.status === 200) {
        authenticated.value = true;
        toast("Signed in", "success");
        await load();
      } else {
        toast("Incorrect username or password.", "error");
      }
    }

    async function logout() {
      await api("POST", "/api/auth/logout");
      authenticated.value = false;
      toast("Signed out", "info");
    }

    async function openCreate() {
      editing.value = null;
      Object.keys(form).forEach(k => delete form[k]);
      errors.value = {};
      await ensureFkOptions(true);
      showForm.value = true;
    }

    async function openEdit(item) {
      editing.value = item.id;
      Object.keys(form).forEach(k => delete form[k]);
      fields.value.forEach(f => { form[f.key] = item[f.key]; });
      errors.value = {};
      await ensureFkOptions(true);
      showForm.value = true;
    }

    function validate() {
      const cfg = entities.find(e => e.name === active.value);
      const errs = {};
      const emailRe = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      cfg.fields.forEach(f => {
        const raw = form[f.key];
        const isEmpty = raw === undefined || raw === null || raw === "";
        if (f.key === "email") {
          if (!isEmpty && !emailRe.test(String(raw).trim())) {
            errs[f.key] = "Enter a valid email address.";
          } else if (isEmpty && f.required) {
            errs[f.key] = `${f.label} is required.`;
          }
          return;
        }
        if (f.type === "fk") {
          if (isEmpty && f.required) errs[f.key] = `${f.label} is required.`;
          return;
        }
        if (f.number) {
          if (isEmpty) {
            if (f.required) errs[f.key] = `${f.label} is required.`;
            return;
          }
          const num = Number(raw);
          if (Number.isNaN(num)) {
            errs[f.key] = `${f.label} must be a number.`;
            return;
          }
          if (f.key === "maxScore") {
            if (num <= 0) errs[f.key] = "Max score must be greater than zero.";
          } else if (f.key === "score") {
            const max = Number(form.maxScore);
            if (num < 0 || (form.maxScore !== "" && !Number.isNaN(max) && num > max)) {
              errs[f.key] = "Score must be a number between 0 and max score.";
            }
          } else if (num <= 0) {
            errs[f.key] = `${f.label} must be a positive number.`;
          }
          return;
        }
        if (isEmpty && f.required) {
          errs[f.key] = `${f.label} is required.`;
        }
      });
      return errs;
    }

    async function save() {
      const cfg = entities.find(e => e.name === active.value);
      errors.value = {};
      const validation = validate();
      if (Object.keys(validation).length > 0) {
        errors.value = validation;
        toast("Please correct the highlighted fields and try again.", "error");
        return;
      }
      const payload = {};
      cfg.fields.forEach(f => {
        if (f.type === "fk") {
          payload[f.key] = (form[f.key] === "" || form[f.key] === null || form[f.key] === undefined) ? null : Number(form[f.key]);
        } else {
          payload[f.key] = f.number ? Number(form[f.key]) : form[f.key];
        }
      });
      const url = editing.value ? `/api/${cfg.name}/${editing.value}` : `/api/${cfg.name}`;
      const r = await api(editing.value ? "PUT" : "POST", url, payload);
      if (r.unauthorized) {
        authenticated.value = false;
        toast("You are not authorized. Please log in again.", "error");
        return;
      }
      if (r.status === 400) {
        errors.value = humanizeFieldErrors(r.data && r.data.errors);
        toast("Please correct the highlighted fields and try again.", "error");
        return;
      }
      if (r.status === 200 || r.status === 201) {
        showForm.value = false;
        toast(editing.value ? "Updated" : "Created", "success");
        await ensureFkOptions();
        await load();
      } else {
        toast(statusMessage(r.status), "error");
      }
    }

    function askDelete(item) {
      confirmDelete.open = true;
      confirmDelete.id = item.id;
    }

    async function doDelete() {
      const cfg = entities.find(e => e.name === active.value);
      const r = await api("DELETE", `/api/${cfg.name}/${confirmDelete.id}`);
      confirmDelete.open = false;
      if (r.unauthorized) {
        authenticated.value = false;
        toast("You are not authorized. Please log in again.", "error");
        return;
      }
      if (r.status === 409) {
        toast("This record can't be deleted because other records depend on it.", "error");
      } else if (r.status === 204) {
        toast("Deleted", "success");
        await ensureFkOptions();
        await load();
      } else {
        toast(statusMessage(r.status), "error");
      }
    }

    onMounted(async () => {
      const r = await api("GET", "/api/students?page=1&pageSize=1");
      if (r.unauthorized) {
        authenticated.value = false;
      } else {
        authenticated.value = true;
        await load();
      }
    });

    return {
      authenticated, loginUser, loginPass, entities, active, items, page, pageSize, loading,
      toasts, showForm, editing, form, errors, confirmDelete, fields, options,
      fkLabel, fkPlaceholder, displayFk,
    load, selectEntity, doLogin, logout, openCreate, openEdit, save, askDelete, doDelete,
    ensureFkOptions
    };
  }
}).mount("#app");
