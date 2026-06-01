/**
 * 递归脱敏工具
 * 自动隐藏 password, token 等敏感字段
 */
export function sanitize(data: unknown): unknown {
  if (!data || typeof data !== 'object') {
    return data;
  }

  // 深度克隆，避免修改原始请求对象
  if (Array.isArray(data)) {
    return data.map((item) => sanitize(item));
  }

  const result = { ...(data as Record<string, unknown>) };
  const sensitiveFields = ['password', 'token', 'secret', 'authorization'];

  for (const key in result) {
    if (sensitiveFields.includes(key.toLowerCase())) {
      result[key] = '***MASKED***';
    } else if (typeof result[key] === 'object' && result[key] !== null) {
      result[key] = sanitize(result[key]);
    }
  }

  return result;
}
