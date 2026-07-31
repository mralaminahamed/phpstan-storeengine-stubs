# StoreEngine Stubs

[![Latest Version](https://img.shields.io/packagist/v/mralaminahamed/storeengine-stubs.svg?color=4CC61E&style=flat-square)](https://packagist.org/packages/mralaminahamed/storeengine-stubs)
[![Downloads](https://img.shields.io/packagist/dt/mralaminahamed/storeengine-stubs.svg?style=flat-square)](https://packagist.org/packages/mralaminahamed/storeengine-stubs/stats)
[![License](https://img.shields.io/packagist/l/mralaminahamed/storeengine-stubs.svg?style=flat-square)](./LICENSE)
[![PHP Version](https://img.shields.io/packagist/php-v/mralaminahamed/storeengine-stubs.svg?style=flat-square)](./composer.json)

PHP stub declarations for the [StoreEngine](https://wordpress.org/plugins/storeengine/) plugin, for IDE completion and static analysis.
Generated with [php-stubs/generator](https://github.com/php-stubs/generator) directly from the
plugin source.

Generated from **StoreEngine 2.2.0** — 708 classes · 9 interfaces · 27 traits · 173 functions · 1 constant.

## 🚀 Features

- Complete class, interface, trait and function declarations
- Constants in a separate file, so PHPStan can scan them rather than analyse them
- IDE autocompletion for a plugin that is not a Composer dependency
- Reproducible: the source is downloaded from WordPress.org, never vendored

## 📋 Requirements

- PHP >= 7.4
- Composer

## 📦 Installation

```bash
composer require --dev mralaminahamed/storeengine-stubs
```

Or download the stub files directly:

- [storeengine-stubs.stub](https://raw.githubusercontent.com/mralaminahamed/phpstan-storeengine-stubs/main/storeengine-stubs.stub)
- [storeengine-constants-stubs.stub](https://raw.githubusercontent.com/mralaminahamed/phpstan-storeengine-stubs/main/storeengine-constants-stubs.stub)

## 🔧 Configuration

Add both files to PHPStan. `scanFiles` rather than `bootstrapFiles`: the stubs declare
symbols for analysis, they are not meant to be executed.

```neon
parameters:
    scanFiles:
        - vendor/mralaminahamed/storeengine-stubs/storeengine-stubs.stub
        - vendor/mralaminahamed/storeengine-stubs/storeengine-constants-stubs.stub
```

For IDE completion, point your IDE at the same files — in PhpStorm, mark them as an *Include
Path* rather than a source root, so the empty method bodies never shadow the real plugin.

## 🔍 Quick usage example

```php
<?php
$product = new \StoreEngine\Classes\Product();

// Note: most STOREENGINE_* constants are defined at runtime — see Limitations.
```

## ⚠️ Limitations

- **Stubs are a snapshot.** They describe StoreEngine 2.2.0. Regenerate when the plugin
  changes a signature, or pin the stub version alongside the plugin version you support.
- **Method bodies are empty by design.** PHPStan reads declarations and types; it never needs
  the implementation. Do not load these files at runtime.
- **Only top-level constants are captured.** Only `STOREENGINE_CHECKOUT` is captured. StoreEngine defines the rest inside `StoreEngine::define_constants()`, and a stub generator reads top-level declarations only — see Limitations below. A constant defined inside a
  function or method is invisible to any stub generator; declare those in your own
  `bootstrapFiles`, or list them under PHPStan's `dynamicConstantNames`.

## 🔄 Regenerating

```bash
composer install
composer generate          # reads source/storeengine, writes both .stub files
composer release           # tag a new version for each untagged upstream release
```

`bin/generate.sh` expects the plugin unpacked at `source/storeengine`; `bin/release-latest-versions.sh`
downloads each version from WordPress.org and tags it. Sources are gitignored — the repository
carries stubs, not a copy of the plugin.

The finder reads `includes/` and `addons/`. Assets, templates, language files and `vendor/` are excluded:
they declare nothing a consumer calls, and vendored packages ship their own stubs.

## 📁 Package structure

```
phpstan-storeengine-stubs/
├── bin/                              # generate.sh, release scripts
├── configs/                          # finder.php (what to read), bootstrap.php (WP constants)
├── source/                           # plugin source, gitignored
├── tests/                            # smoke tests over the generated stubs
├── storeengine-stubs.stub               # classes, interfaces, traits, functions
├── storeengine-constants-stubs.stub     # constants only
└── phpstan.neon                      # analyses the stubs themselves
```

## 📝 License

The tooling in this repository is MIT. The generated stubs are derived from StoreEngine, which is
GPL-licensed; using them for static analysis is fair use of the declarations, but redistributing
them as your own product is not. See [LICENSE](./LICENSE).
