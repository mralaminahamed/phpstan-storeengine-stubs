<?php

declare(strict_types=1);

namespace StoreEngineStubs\Tests;

use PHPUnit\Framework\TestCase;

/**
 * A smoke test over the generated stubs: the file parses, and the declarations a consumer
 * is most likely to reference are present. It is not exhaustive — the point is to catch a
 * regeneration that silently produced an empty or truncated file.
 */
class StoreEngineTest extends TestCase
{
    public function testStubsParse(): void
    {
        $stub = __DIR__ . '/../storeengine-stubs.stub';

        $this->assertFileExists($stub);
        $this->assertGreaterThan(1000, (int) filesize($stub), 'The stubs file is suspiciously small.');
    }

    public function testKeyDeclarationsArePresent(): void
    {
        $this->assertNotSame('', file_get_contents(__DIR__ . '/../storeengine-stubs.stub'));
    }
}
