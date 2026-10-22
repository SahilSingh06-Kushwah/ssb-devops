<?php
declare(strict_types=1);
require __DIR__ . '/bootstrap.php';

$errors = [];
$name = '';
$college = '';

// CREATE: add a new student record
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $name    = trim((string) ($_POST['name'] ?? ''));
    $college = trim((string) ($_POST['college'] ?? ''));

    if ($name === '' || mb_strlen($name) > 100) {
        $errors[] = 'Name is required (max 100 characters).';
    }
    if ($college === '' || mb_strlen($college) > 150) {
        $errors[] = 'College name is required (max 150 characters).';
    }

    if (!$errors) {
        $stmt = db()->prepare('INSERT INTO students (name, college) VALUES (:name, :college)');
        $stmt->execute([':name' => $name, ':college' => $college]);
        flash('Record added successfully.');
        header('Location: index.php');
        exit;
    }
}

// READ: list all records
$students = db()->query('SELECT id, name, college, created_at FROM students ORDER BY id DESC')->fetchAll();
$flash = flash();

page_header('Student Records - SSB Digital Demo');
?>
<h1>Student Records v2</h1>

<?php if ($flash): ?>
    <div class="<?= e($flash['type']) ?>"><?= e($flash['msg']) ?></div>
<?php endif; ?>
<?php foreach ($errors as $err): ?>
    <div class="err"><?= e($err) ?></div>
<?php endforeach; ?>

<form method="post" action="index.php">
    <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>">
    <label for="name">Student name</label>
    <input type="text" id="name" name="name" maxlength="100" value="<?= e($name) ?>" required>
    <label for="college">College name</label>
    <input type="text" id="college" name="college" maxlength="150" value="<?= e($college) ?>" required>
    <button type="submit">Add record</button>
</form>

<table>
    <thead><tr><th>ID</th><th>Name</th><th>College</th><th>Added</th><th></th></tr></thead>
    <tbody>
    <?php foreach ($students as $s): ?>
        <tr>
            <td><?= (int) $s['id'] ?></td>
            <td><?= e($s['name']) ?></td>
            <td><?= e($s['college']) ?></td>
            <td><?= e($s['created_at']) ?></td>
            <td><a href="edit.php?id=<?= (int) $s['id'] ?>">Edit</a></td>
        </tr>
    <?php endforeach; ?>
    <?php if (!$students): ?>
        <tr><td colspan="5">No records yet.</td></tr>
    <?php endif; ?>
    </tbody>
</table>
<?php page_footer();
