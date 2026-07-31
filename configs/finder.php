<?php
/**
 * Which StoreEngine files to read.
 *
 * StoreEngine gates several capabilities behind addons, so `addons/` is included as well as `includes/`: code that checks for an addon needs its classes to exist as declarations even when the addon is inactive.
 */

use StubsGenerator\Finder;

return Finder::create()
    ->in( array(
        'source/storeengine/includes',
        'source/storeengine/addons',
    ) )
    ->append(
        Finder::create()
            ->in( array( 'source/storeengine' ) )
            ->files()
            ->depth( '< 1' )
            ->path( 'storeengine.php' )
    )
    ->sortByName( true )
;
