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
import { RoomsService } from './rooms.service';
import { RoomType } from './room.entity';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('organizations/:organizationId/buildings/:buildingId/rooms')
export class RoomsController {
  constructor(private roomsService: RoomsService) {}

  @Roles(UserRole.LANDLORD)
  @Post()
  async create(
    @Param('organizationId') organizationId: string,
    @Param('buildingId') buildingId: string,
    @Body()
    body: {
      name: string;
      floor?: number;
      type?: RoomType;
      rentAmount: number;
      storageAmount?: number;
      description?: string;
    },
  ) {
    return this.roomsService.create({ ...body, buildingId, organizationId });
  }

  @Roles(UserRole.LANDLORD, UserRole.CARETAKER)
  @Get()
  async findAll(
    @Param('organizationId') organizationId: string,
    @Param('buildingId') buildingId: string,
  ) {
    return this.roomsService.findAll(buildingId, organizationId);
  }

  @Roles(UserRole.LANDLORD, UserRole.CARETAKER)
  @Get('vacant')
  async findVacant(
    @Param('organizationId') organizationId: string,
    @Param('buildingId') buildingId: string,
  ) {
    return this.roomsService.findVacant(buildingId, organizationId);
  }

  @Roles(UserRole.LANDLORD, UserRole.CARETAKER)
  @Get(':id')
  async findOne(
    @Param('organizationId') organizationId: string,
    @Param('id') id: string,
  ) {
    return this.roomsService.findById(id, organizationId);
  }

  @Roles(UserRole.LANDLORD)
  @Patch(':id')
  async update(
    @Param('organizationId') organizationId: string,
    @Param('id') id: string,
    @Body()
    body: Partial<{
      name: string;
      floor: number;
      type: RoomType;
      rentAmount: number;
      storageAmount: number;
      description: string;
    }>,
  ) {
    return this.roomsService.update(id, organizationId, body);
  }

  @Roles(UserRole.LANDLORD, UserRole.CARETAKER)
  @Patch(':id/vacate')
  async vacate(
    @Param('organizationId') organizationId: string,
    @Param('id') id: string,
  ) {
    return this.roomsService.vacateRoom(id, organizationId);
  }
}