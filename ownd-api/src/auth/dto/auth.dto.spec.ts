import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { UpdateProfileDto } from './auth.dto';

describe('UpdateProfileDto', () => {
  it('accepts expiry-day reminders', async () => {
    const dto = plainToInstance(UpdateProfileDto, {
      notificationLeadDays: 0,
    });

    expect(await validate(dto)).toHaveLength(0);
  });

  it('rejects unsupported reminder lead days', async () => {
    const dto = plainToInstance(UpdateProfileDto, {
      notificationLeadDays: 2,
    });

    expect(await validate(dto)).not.toHaveLength(0);
  });
});
