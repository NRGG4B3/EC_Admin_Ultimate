import * as React from "react"
import { cn } from "./utils"

// Minimal variant class helper to avoid external dependency on class-variance-authority
const baseBadge = "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
const variantClasses: Record<string, string> = {
  default: "border-transparent bg-primary text-primary-foreground hover:bg-primary/80",
  secondary: "border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80",
  destructive: "border-transparent bg-destructive text-destructive-foreground hover:bg-destructive/80",
  outline: "text-foreground",
}
function badgeVariants({ variant = "default" }: { variant?: keyof typeof variantClasses }) {
  return cn(baseBadge, variantClasses[variant])
}

// Relaxed, explicit props to avoid VariantProps inference issues when used in JSX
export type BadgeProps = React.HTMLAttributes<HTMLDivElement> & {
  variant?: 'default' | 'secondary' | 'destructive' | 'outline';
  className?: string;
  children?: React.ReactNode;
}

function Badge({ className, variant = 'default', ...props }: BadgeProps) {
  return <div className={cn(badgeVariants({ variant }), className)} {...props} />
}

export { Badge, badgeVariants }