function aws_export_creds_to_env --wraps='eval $(aws configure export-credentials --profile preprod --format env)' --description 'alias aws_export_creds_to_env=eval $(aws configure export-credentials --profile preprod --format env)'
  eval $(aws configure export-credentials --profile preprod --format env) $argv
        
end
