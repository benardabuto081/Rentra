import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from './roles.decorator';
import { UserRole } from '../users/user.entity';

/**
 * Reads the roles set by @Roles() on the handler (or the controller class)
 * and compares them against req.user.role, which JwtAuthGuard attaches
 * before this guard runs.
 *
 * IMPORTANT: This guard must always run AFTER JwtAuthGuard, since it
 * depends on req.user already being populated. Order matters in
 * @UseGuards(JwtAuthGuard, RolesGuard).
 *
 * If a route has no @Roles() decorator, this guard allows the request
 * through — it only restricts routes that explicitly declare which
 * roles are permitted.
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user || !requiredRoles.includes(user.role)) {
      throw new ForbiddenException(
        'You do not have permission to access this resource.',
      );
    }

    return true;
  }
}