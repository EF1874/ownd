import { validate } from 'class-validator';
import { CreateItemDto } from './create-item.dto';
import { plainToInstance } from 'class-transformer';

describe('CreateItemDto', () => {
  it('should fail if currentCycle is less than 1', async () => {
    const dto = plainToInstance(CreateItemDto, {
      name: 'Test Item',
      price: 100,
      currentCycle: 0,
    });
    const errors = await validate(dto);
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].constraints).toHaveProperty('min');
  });

  it('should pass if currentCycle is 1', async () => {
    const dto = plainToInstance(CreateItemDto, {
      name: 'Test Item',
      price: 100,
      currentCycle: 1,
    });
    const errors = await validate(dto);
    expect(errors.length).toBe(0);
  });

  it('should pass if currentCycle is missing (as it is optional)', async () => {
    const dto = plainToInstance(CreateItemDto, {
      name: 'Test Item',
      price: 100,
    });
    const errors = await validate(dto);
    expect(errors.length).toBe(0);
  });
});
