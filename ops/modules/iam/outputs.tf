output "iam_role_arn" {
  value = aws_iam_role.github_actions.arn
}

output "iam_policy_arn" {
  value = aws_iam_policy.github_actions.arn
}
