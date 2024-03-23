# Point - Cognito

Esta documentação aborda a configuração de um ambiente na AWS usando Terraform para gerenciar um pool de usuários do Cognito e integrá-lo a uma função Lambda. Este exemplo específico demonstra como preparar o ambiente para usar uma função Lambda como trigger antes do registro de usuários (pre-sign up) no AWS Cognito.

## Requisitos

- Terraform instalado
- CLI da AWS configurada com credenciais apropriadas
- Uma função Lambda existente para ser usada como trigger

## Configuração

### Provedor AWS

O bloco provider especifica a configuração do provedor AWS. No exemplo, estamos utilizando a região us-east-2.

```hcl
    provider "aws" {
        region = "us-east-2"
    }
```

### Backend Terraform
O Terraform armazena o estado da infraestrutura. No exemplo abaixo, usamos um bucket S3 da AWS para armazenar o estado do Terraform.

```hcl

    terraform {
        backend "s3" {
            bucket  = "point-terraform-state"
            key     = "point-cognito.tfstate"
            region  = "us-east-2"
            encrypt = true
        }
    }
```

### Recurso AWS Lambda Function

Define uma referência a uma função Lambda existente para ser usada como trigger. Aqui, estamos interessados na ARN da função para configuração posterior.

```hcl
    data "aws_lambda_function" "point_lambda_pre_sign_up" {
    function_name = "point_lambda_pre_sign_up"
    }
```

### Recurso AWS Cognito User Pool

Cria um novo pool de usuários no Cognito com configurações específicas, incluindo a integração com a função Lambda para o evento pre-sign up.

```hcl
    resource "aws_cognito_user_pool" "cognito_user_pool" {
    name = "point"

    lambda_config {
        pre_sign_up = data.aws_lambda_function.point_lambda_pre_sign_up.arn
    }

    password_policy {
        minimum_length    = 6
        require_lowercase = false
        require_numbers   = false
        require_symbols   = false
        require_uppercase = false
    }
    mfa_configuration = "OFF"
    }
```

### Recurso AWS Cognito User Pool Client

Cria um cliente para o pool de usuários, configurando detalhes como fluxos OAuth permitidos, URLs de callback e logout, entre outros.

```hcl
    resource "aws_cognito_user_pool_client" "point_app_client" {
        name                                 = "point_app_client"
        user_pool_id                         = aws_cognito_user_pool.cognito_user_pool.id
    }
```

### Permissão Lambda

Concede à AWS Cognito a permissão para invocar a função Lambda especificada para o evento de pre-sign up.

```hcl
    resource "aws_lambda_permission" "point_lambda_pre_sign_up_permission" {
        principal     = "cognito-idp.amazonaws.com"
        action        = "lambda:InvokeFunction"
        function_name = data.aws_lambda_function.point_lambda_pre_sign_up.function_name
        source_arn    = aws_cognito_user_pool.cognito_user_pool.arn
    }
```

### Aplicando a Configuração

Após a configuração do arquivo .tf, execute os seguintes comandos na pasta do projeto Terraform:

1. Inicialize o Terraform:

    ```shell
    terraform init
    ```

2. Verifique o plano de execução para garantir que as ações planejadas estão corretas:

    ```shell
    terraform plan
    ```

3. Aplique as configurações para criar os recursos na AWS:

    ```shell
    terraform apply
    ```

Confirme a execução quando solicitado.

## Conclusão

Após a aplicação bem-sucedida, o ambiente AWS estará configurado com um pool de usuários Cognito integrado a uma função Lambda específica para ser executada antes do registro de usuários. Isso permite a execução de lógicas personalizadas, como validações ou modificações no processo de registro.
