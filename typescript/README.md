# Optivem Testing (TypeScript)

[![npm](https://img.shields.io/npm/v/@optivem/optivem-testing)](https://www.npmjs.com/package/@optivem/optivem-testing)
[![License](https://img.shields.io/github/license/optivem/optivem-testing.svg)](LICENSE)

Composable Playwright helpers for channelized tests.

## Installation

```bash
npm install @optivem/optivem-testing
```

## Exports

- `forChannels` and channel primitives from `channel`
- `bindChannels(test)`
- `bindTestEach(test)`
- `channelTest` (legacy convenience helper)

## Example

```typescript
import { test as base, expect } from '@playwright/test';
import { bindChannels, bindTestEach } from '@optivem/optivem-testing';

const _test = base.extend<{ app: MyApp }>({
	app: async ({}, use) => {
		const app = createMyApp();
		await use(app);
		await app.close();
	},
});

const test = Object.assign(_test, {
	each: bindTestEach(_test),
});

const { forChannels } = bindChannels(test);

forChannels('UI', 'API')(() => {
	test.each(['3.5', 'lala'])(
		'rejects non-integer quantity ($quantity)',
		async ({ app, quantity }) => {
			await expect(app.placeOrder(quantity)).resolves.toBeDefined();
		},
	);
});
```

### Additional Channels (`also`)

Reduce UI test count by running only representative data rows on slow channels:

```typescript
const { forChannels } = bindChannels(test);

forChannels('API')(() => {
	test.each([
		{ unitPrice: '20.00', quantity: '5', basePrice: '100.00', also: ['UI'] },   // API + UI
		{ unitPrice: '10.00', quantity: '3', basePrice: '30.00' },                   // API only
		{ unitPrice: '15.50', quantity: '4', basePrice: '62.00' },                   // API only
	])(
		'should place order $unitPrice x $quantity = $basePrice',
		async ({ scenario, unitPrice, quantity, basePrice }) => {
			// Test implementation
		},
	);
});
// Generates 4 tests: API×3 rows + UI×1 row (the one with also)
```

The `also` property accepts a string or string array. When specified, that data row runs on the base channels **plus** the additional channels. When omitted, the row runs on base channels only. This is fully backwards compatible.

## Notes

- This package does **not** define domain fixtures like `app` or `scenario`.
- Build domain fixtures in your test-infrastructure layer, then compose them with these helpers.

## License

[MIT License](LICENSE)

## Links

- [GitHub Repository](https://github.com/optivem/optivem-testing)
- [npm Package](https://www.npmjs.com/package/@optivem/optivem-testing)

---

Built by [Optivem](https://github.com/optivem)
