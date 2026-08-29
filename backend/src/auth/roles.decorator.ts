import { SetMetadata } from '@nestjs/common';
import { UserRole } from '../users/user.entity';

export const ROLES_KEY = 'roles';

/**
 * Marks a route (or an entire controller) as restricted to specific
 * user roles. Must be used together with RolesGuard.
 *
 * Usage:
 *   @Roles(UserRole.LANDLORD, UserRole.CARETAKER)
 *   @Get('financial')
 *   getFinancialSummary() { ... }
 *
 * A route with no @Roles() decorator is accessible to any authenticated
 * user (JwtAuthGuard still applies separately).
 */
export const Roles = (...roles: UserRole[]) => SetMetadata(ROLES_KEY, roles);