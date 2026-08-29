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
import { OrganizationsService } from './organizations.service';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('organizations')
export class OrganizationsController {
  constructor(private organizationsService: OrganizationsService) {}

  @Roles(UserRole.LANDLORD)
  @Post()
  async create(
    @Body()
    body: {
      name: string;
      ownerId: string;
      phone?: string;
      email?: string;
      address?: string;
      city?: string;
    },
  ) {
    return this.organizationsService.create(body);
  }

  @Roles(UserRole.LANDLORD, UserRole.CARETAKER)
  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.organizationsService.findById(id);
  }

  @Roles(UserRole.LANDLORD)
  @Get('owner/:ownerId')
  async findByOwner(@Param('ownerId') ownerId: string) {
    return this.organizationsService.findByOwner(ownerId);
  }

  @Roles(UserRole.LANDLORD)
  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body()
    body: Partial<{
      name: string;
      phone: string;
      email: string;
      address: string;
      city: string;
    }>,
  ) {
    return this.organizationsService.update(id, body);
  }
}