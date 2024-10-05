/*
resource "null_resource" "package_lambdas" {
  for_each = local.scripts

  # Clean the package directory
  provisioner "local-exec" {
    command = "rm -rf ${path.module}/package/${each.key} && mkdir -p ${path.module}/package/${each.key}"
  }

  # Install dependencies and copy script files
  provisioner "local-exec" {
    command = <<EOT
    pip install -r ${each.value.path}/requirements.txt -t ${path.module}/package/${each.key} && \
    cp ${each.value.path}/*.py ${path.module}/package/${each.key}/
    EOT
  }

  # Create zip file
  provisioner "local-exec" {
    command = "cd ${path.module}/package/${each.key} && zip -r ../${each.key}.zip ."
  }

  triggers = {
    script_path = "${each.value.path}"
  }
}

resource "null_resource" "package_lambdas" {
  for_each = local.scripts

  provisioner "local-exec" {
    command = <<EOT
    Write-Host "Packaging ${each.key}..."
    Remove-Item -Path "${path.module}/package/${each.key}" -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -Path "${path.module}/package/${each.key}" -ItemType Directory -Force
    pip install -r "${each.value.path}/requirements.txt" -t "${path.module}/package/${each.key}"
    Copy-Item "${each.value.path}/*.py" -Destination "${path.module}/package/${each.key}"
    Compress-Archive -Path "${path.module}/package/${each.key}/*" -DestinationPath "${path.module}/package/${each.key}.zip" -Force
    Write-Host "Packaging of ${each.key} complete."
    EOT
    interpreter = ["PowerShell", "-Command"]
  }

  triggers = {
    script_path = "${each.value.path}"
  }
}


resource "null_resource" "package_lambdas" {
  for_each = local.scripts

  provisioner "local-exec" {
    command = "C:\\Windows\\System32\\cmd.exe /C C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./scripts/package_lambda.ps1 -FunctionName '${each.key}' -FunctionPath '${each.value.path}'"
  }
     


  triggers = {
    script_path = each.value.path
  }
}

data "archive_file" "lambda_packages" {
  for_each = local.scripts

  type        = "zip"
  source_dir  = "${path.module}/package/${each.key}"
  output_path = "${path.module}/package/${each.key}.zip"

  depends_on = [null_resource.package_lambdas]
}

resource "null_resource" "package_lambdas" {
  for_each = local.scripts

  # Clean the package directory
  provisioner "local-exec" {
    command = "if exist ${path.module}\\package\\${each.key} rmdir /s /q ${path.module}\\package\\${each.key} && mkdir ${path.module}\\package\\${each.key}"
    interpreter = ["cmd", "/C"]
  }

  # Install dependencies and copy script files
  provisioner "local-exec" {
    command = <<EOT
    pip install -r ${each.value.path}\\requirements.txt -t ${path.module}\\package\\${each.key} && ^
    copy ${each.value.path}\\*.py ${path.module}\\package\\${each.key}\\
    EOT
    interpreter = ["cmd", "/C"]
  }

  # Create zip file
  provisioner "local-exec" {
    command = "cd ${path.module}\\package\\${each.key} && powershell Compress-Archive -Path * -DestinationPath ..\\${each.key}.zip -Force"
    interpreter = ["cmd", "/C"]
  }

  triggers = {
    script_path = "${each.value.path}"
  }
}

data "archive_file" "lambda_packages" {
  for_each = local.scripts

  type        = "zip"
  source_dir  = "${path.module}/package/${each.key}"
  output_path = "${path.module}/package/${each.key}.zip"

  depends_on = [null_resource.package_lambdas]
}
*/