import {
  Controller,
  Get,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { UserRole } from '../users/user.entity';
import { DashboardService } from './dashboard.service';

@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.LANDLORD, UserRole.CARETAKER)
@Controller('organizations/:organizationId/dashboard')
export class DashboardController {
  constructor(private dashboardService: DashboardService) {}

  // GET /organizations/:organizationId/dashboard/overview
  @Get('overview')
  async getOverview(@Param('organizationId') organizationId: string) {
    return this.dashboardService.getOverview(organizationId);
  }

  // GET /organizations/:organizationId/dashboard/financial?month=6&year=2026
  @Get('financial')
  async getFinancialSummary(
    @Param('organizationId') organizationId: string,
    @Query('month') month: number,
    @Query('year') year: number,
  ) {
    return this.dashboardService.getFinancialSummary(
      organizationId,
      month,
      year,
    );
  }

  // GET /organizations/:organizationId/dashboard/buildings
  @Get('buildings')
  async getBuildingSummary(@Param('organizationId') organizationId: string) {
    return this.dashboardService.getBuildingSummary(organizationId);
  }
}