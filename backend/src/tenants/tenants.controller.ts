import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { UserRole } from '../users/user.entity';
import { TenantsService } from './tenants.service';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('organizations/:organizationId/tenants')
export class TenantsController {
  constructor(private tenantsService: TenantsService) {}

  @Roles(UserRole.LANDLORD)
  @Post()
  async create(
    @Param('organizationId') organizationId: string,
    @Body()
    body: {
      userId: string;
      roomId: string;
      buildingId: string;
      rentAmount: number;
      storageAmount?: number;
      depositAmount?: number;
      moveInDate: Date;
      notes?: string;
    },
  ) {
    return this.tenantsService.create({ ...body, organizationId });
  }

  @Roles(UserRole.LANDLORD, UserRole.CARETAKER)
  @Get()
  async findAll(@Param('organizationId') organizationId: string) {
    return this.tenantsService.findAll(organizationId);
  }

  @Roles(UserRole.LANDLORD, UserRole.CARETAKER)
  @Get('active')
  async findActive(@Param('organizationId') organizationId: string) {
    return this.tenantsService.findActive(organizationId);
  }

  @Roles(UserRole.LANDLORD, UserRole.CARETAKER)
  @Get(':id')
  async findOne(
    @Param('organizationId') organizationId: string,
    @Param('id') id: string,
  ) {
    return this.tenantsService.findById(id, organizationId);
  }

  @Roles(UserRole.LANDLORD, UserRole.CARETAKER)
  @Patch(':id/notice')
  async giveNotice(
    @Param('organizationId') organizationId: string,
    @Param('id') id: string,
    @Body() body: { noticeDate: Date },
  ) {
    return this.tenantsService.giveNotice(id, organizationId, body.noticeDate);
  }

  @Roles(UserRole.LANDLORD, UserRole.CARETAKER)
  @Patch(':id/vacate')
  async vacate(
    @Param('organizationId') organizationId: string,
    @Param('id') id: string,
    @Body() body: { moveOutDate: Date },
  ) {
    return this.tenantsService.vacate(id, organizationId, body.moveOutDate);
  }

  @Roles(UserRole.LANDLORD)
  @Patch(':id')
  async update(
    @Param('organizationId') organizationId: string,
    @Param('id') id: string,
    @Body() body: Partial<{
      rentAmount: number;
      storageAmount: number;
      notes: string;
    }>,
  ) {
    return this.tenantsService.update(id, organizationId, body);
  }
}