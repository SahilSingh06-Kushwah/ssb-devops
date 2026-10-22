<?php
declare(strict_types=1);
require __DIR__ . '/bootstrap.php';

$id = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT) ?: filter_input(INPUT_POST, 'id', FILTER_VALIDATE_INT);
if (!$id) {
    http_response_code(400);
    exit('Invalid record id.');
}

$stmt = db()->prepare('SELECT id, name, college FROM students WHERE id = :id');
$stmt->execute([':id' => $id]);
$student = $stmt->fetch();
if (!$student) {
    http_response_code(404);
    exit('Record not found.');
}

$errors = [];

// UPDATE: save changes to an existing record
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
        $upd = db()->prepare('UPDATE students SET name = :name, college = :college WHERE id = :id');
        $upd->execute([':name' => $name, ':college' => $college, ':id' => $id]);
        flash('Record updated successfully.');
        header('Location: index.php');
        exit;
    }
    $student['name'] = $name;
    $student['college'] = $college;
}

page_header('Edit Record - SSB Digital Demo');
?>
<h1>Edit Record #<?= (int) $student['id'] ?></h1>

<?php foreach ($errors as $err): ?>
    <div class="err"><?= e($err) ?></div>
<?php endforeach; ?>

<form method="post" action="edit.php?id=<?= (int) $student['id'] ?>">
    <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>">
    <input type="hidden" name="id" value="<?= (int) $student['id'] ?>">
    <label for="name">Student name</label>
    <input type="text" id="name" name="name" maxlength="100" value="<?= e($student['name']) ?>" required>
    <label for="college">College name</label>
    <input type="text" id="college" name="college" maxlength="150" value="<?= e($student['college']) ?>" required>
    <button type="submit">Save changes</button>
    <a class="btn" style="background:#6c757d" href="index.php">Cancel</a>
</form>
<?php page_footer();
