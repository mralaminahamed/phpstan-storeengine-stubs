<?php

declare(strict_types=1);

namespace StoreEngineStubs\Tests;

use PHPUnit\Framework\TestCase;

/**
 * The constants stubs are a separate file because PHPStan scans them rather than analysing
 * them; this checks the generator actually captured them.
 *
 * StoreEngine is the awkward case: it defines almost every STOREENGINE_* constant inside
 * StoreEngine::define_constants(), and a stub generator reads top-level declarations only —
 * so one constant is all there is to assert. Consumers needing the rest declare them in their
 * own bootstrap file or list them under PHPStan's dynamicConstantNames; the README says so.
 */
class ConstantsTest extends TestCase
{
    public function testConstantsAreDefined(): void
    {
        $this->assertTrue(defined('STOREENGINE_CHECKOUT'), 'STOREENGINE_CHECKOUT is missing from the constants stubs.');
    }
}
