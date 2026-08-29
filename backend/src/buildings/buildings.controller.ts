import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { UserRole } from '../users/user.entity';
import { BuildingsService } from './buildings.service';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('organizations/:organizationId/buildings')
export class BuildingsController {
  constructor(private buildingsService: BuildingsService) {}

  // POST /organizations/:organizationId/buildings
  @Roles(UserRole.LANDLORD)
  @Post()
  async create(
    @Param('organizationId') organizationId: string,
    @Body()
    body: {
      name: string;
      address?: string;
      city?: string;
      county?: string;
      totalFloors?: number;
      description?: string;
    },
  ) {
    return this.buildingsService.create({ ...body, organizationId });
  }

  // GET /organizations/:organizationId/buildings
  @Roles(UserRole.LANDLORD, UserRole.CARETAKER)
  @Get()
  async findAll(@Param('organizationId') organizationId: string) {
    return this.buildingsService.findAll(organizationId);
  }

  // GET /organizations/:organizationId/buildings/:id
  @Roles(UserRole.LANDLORD, UserRole.CARETAKER)
  @Get(':id')
  async findOne(
    @Param('organizationId') organizationId: string,
    @Param('id') id: string,
  ) {
    return this.buildingsService.findById(id, organizationId);
  }

  // PATCH /organizations/:organizationId/buildings/:id
  @Roles(UserRole.LANDLORD)
  @Patch(':id')
  async update(
    @Param('organizationId') organizationId: string,
    @Param('id') id: string,
    @Body()
    body: Partial<{
      name: string;
      address: string;
      city: string;
      county: string;
      totalFloors: number;
      description: string;
    }>,
  ) {
    return this.buildingsService.update(id, organizationId, body);
  }

  // DELETE /organizations/:organizationId/buildings/:id
  @Roles(UserRole.LANDLORD)
  @Delete(':id')
  async deactivate(
    @Param('organizationId') organizationId: string,
    @Param('id') id: string,
  ) {
    return this.buildingsService.deactivate(id, organizationId);
  }
}