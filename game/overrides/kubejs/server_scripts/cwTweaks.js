//Part of code created by MC7, modified by Onmod

// Last modified 10/18/2025, Pond.

// Modification policy: please comment "ADDITION: [Description]" next to all changes you made when you recieved the file. 
// Please remove all such "ADDITION: [D]" messages you inherit.

ServerEvents.recipes(event => {
  console.log('CW Recipe Tweaks has fired.')

  //Following script wrote by Onmod
  event.shaped(
    Item.of('kubejs:circuit_board'),
    [
      'AAB',
      'CD '
    ],
    {
      A: 'createdeco:netherite_nugget',
      B: 'the_deeper_void:raw_rutile',
      C: 'create:copper_sheet',
      D: 'minecraft:emerald'
    }
  )

  event.remove({ output: "create:blaze_burner" })

  event.shaped(
    Item.of('create:blaze_burner'),
    [
      'AAA',
      'ABA',
      'ACA'
    ],
    {
      A: 'create_netherless:coal_rod',
      B: 'minecraft:soul_sand',
      C: 'create:empty_blaze_burner'
    }
  )

  event.shapeless('minecraft:totem_of_undying',
    [
      'kubejs:defib',
      'kubejs:shock',
      'kubejs:cables'
    ]
  )

  event.shapeless('create:blaze_cake', [
    'create:blaze_cake_base',
    'minecraft:lava_bucket'
  ]).replaceIngredient('minecraft:lava_bucket', 'minecraft:bucket')

  event.shapeless('create:blaze_cake_base', [
    'minecraft:netherrack',
    '#forge:eggs',
    'minecraft:sugar'
  ])


  event.shaped(
    Item.of('kubejs:advanced_circuit_board'),
    [
      'AAB',
      'ACD'
    ],
    {
      A: 'createdeco:netherite_sheet',
      B: 'the_deeper_void:raw_rutile',
      C: 'create:copper_sheet',
      D: 'minecraft:emerald'
    }
  )

  event.shaped(
    Item.of('minecraft:nether_star'),
    [
      'ABA',
      'BCB',
      'ABA'
    ],
    {
      A: 'kubejs:advanced_circuit_board',
      B: 'minecraft:diamond_block',
      C: 'minecraft:sea_lantern'
    }
  )


  event.remove({ output: "minecraft:netherite_upgrade_smithing_template" })

  event.shaped(
    Item.of('minecraft:netherite_upgrade_smithing_template'),
    [
      'ABA',
      'BCB',
      'ABA'
    ],
    {
      A: 'mcore:titanium_ingot',
      B: 'mcore:steel_ingot',
      C: 'minecraft:diamond'
    }
  )

  event.remove({ output: "securitycraft:protecto" })

  event.shaped(
    Item.of('securitycraft:protecto'),
    [
      'ABA',
      'ACA',
      'ACA'
    ],
    {
      A: 'securitycraft:reinforced_obsidian',
      B: 'minecraft:daylight_detector',
      C: 'kubejs:circuit_board',
    }
  )

  event.remove({ output: "sophisticatedbackpacks:xp_pump_upgrade" })

  event.shaped(
    Item.of('sophisticatedbackpacks:xp_pump_upgrade'),
    [
      'ABA',
      'CDC',
      'ABA'
    ],
    {
      A: 'minecraft:redstone',
      B: 'kubejs:circuit_board',
      C: 'minecraft:bottle_o_enchanting',
      D: 'sophisticatedbackpacks:advanced_pump_upgrade'
    }
  )

  event.remove({ output: "railways:remote_lens" })

  event.shaped(
    Item.of('railways:remote_lens'),
    [
      'ABC'
    ],
    {
      A: 'create:precision_mechanism',
      B: 'kubejs:circuit_board',
      C: 'create:brass_sheet'
    }
  )

  event.remove({ output: "minecraft:ender_chest" })

  event.shaped(
    Item.of('minecraft:ender_chest'),
    [
      'ABA',
      'ACA',
      'ABA'
    ],
    {
      A: 'minecraft:obsidian',
      B: 'minecraft:ender_pearl',
      C: 'kubejs:circuit_board'
    }
  )

  event.remove({ output: "securitycraft:retinal_scanner" })

  event.shaped(
    Item.of('securitycraft:retinal_scanner'),
    [
      'AAA',
      'ABA',
      'ABA'
    ],
    {
      A: 'securitycraft:reinforced_cobblestone',
      B: 'kubejs:circuit_board',
    }
  )

  event.remove({ output: "securitycraft:rift_stabilizer" })

  event.shaped(
    Item.of('securitycraft:rift_stabilizer'),
    [
      'AEA',
      'BCB',
      'DDD'
    ],
    {
      A: 'minecraft:gold_ingot',
      B: 'kubejs:circuit_board',
      C: 'securitycraft:reinforced_block_of_diamond',
      D: 'securitycraft:reinforced_block_of_iron',
      E: 'minecraft:ender_pearl'
    }
  )

  event.remove({ output: "minecraft:netherite_helmet" })

  event.shaped(
    Item.of('minecraft:netherite_helmet'),
    [
      'ACA',
      'B B'
    ],
    {
      A: 'createdeco:netherite_nugget',
      B: 'minecraft:netherite_ingot',
      C: 'mcore:steel_ingot'
    }
  )

  event.remove({ output: "minecraft:netherite_chestplate" })

  event.shaped(
    Item.of('minecraft:netherite_chestplate'),
    [
      'B B',
      'ACA',
      'AAA'
    ],
    {
      A: 'createdeco:netherite_nugget',
      B: 'minecraft:netherite_ingot',
      C: 'mcore:steel_ingot'
    }
  )

  event.remove({ output: "minecraft:netherite_leggings" })

  event.shaped(
    Item.of('minecraft:netherite_leggings'),
    [
      'ACA',
      'B B',
      'A A'
    ],
    {
      A: 'createdeco:netherite_nugget',
      B: 'minecraft:netherite_ingot',
      C: 'mcore:steel_ingot'
    }
  )

  event.remove({ output: "minecraft:netherite_boots" })

  event.shaped(
    Item.of('minecraft:netherite_boots'),
    [
      'B B',
      'A A',
    ],
    {
      A: 'createdeco:netherite_nugget',
      B: 'mcore:steel_ingot'
    }
  )

  //Recipe changes to fit with visual looks
  //diamond

  event.remove({ output: "minecraft:diamond_helmet" })

  event.shaped(
    Item.of('minecraft:diamond_helmet'),
    [
      'ABA',
      'A A',
    ],
    {
      A: 'minecraft:diamond',
      B: 'mcore:steel_ingot'
    }
  )

  event.remove({ output: "minecraft:diamond_chestplate" })

  event.shaped(
    Item.of('minecraft:diamond_chestplate'),
    [
      'A A',
      'ABA',
      'AAA'
    ],
    {
      A: 'minecraft:diamond',
      B: 'mcore:steel_ingot'
    }
  )

  event.remove({ output: "minecraft:diamond_leggings" })

  event.shaped(
    Item.of('minecraft:diamond_leggings'),
    [
      'ABA',
      'A A',
      'A A'
    ],
    {
      A: 'minecraft:diamond',
      B: 'mcore:steel_ingot'
    }
  )

  event.remove({ output: "minecraft:diamond_boots" })

  event.shaped(
    Item.of('minecraft:diamond_boots'),
    [
      'B B',
      'A A',
    ],
    {
      A: 'minecraft:diamond',
      B: 'mcore:steel_ingot'
    }
  )

  //gold

  event.remove({ output: "minecraft:golden_helmet" })

  event.shaped(
    Item.of('minecraft:golden_helmet'),
    [
      'ABA',
      'A A',
    ],
    {
      A: 'minecraft:gold_ingot',
      B: 'mcore:steel_ingot'
    }
  )

  event.remove({ output: "minecraft:golden_chestplate" })

  event.shaped(
    Item.of('minecraft:golden_chestplate'),
    [
      'A A',
      'ABA',
      'AAA'
    ],
    {
      A: 'minecraft:gold_ingot',
      B: 'mcore:steel_ingot'
    }
  )

  event.remove({ output: "minecraft:golden_leggings" })

  event.shaped(
    Item.of('minecraft:golden_leggings'),
    [
      'ABA',
      'A A',
      'A A'
    ],
    {
      A: 'minecraft:gold_ingot',
      B: 'mcore:steel_ingot'
    }
  )

  event.remove({ output: "minecraft:golden_boots" })

  event.shaped(
    Item.of('minecraft:golden_boots'),
    [
      'B B',
      'A A',
    ],
    {
      A: 'minecraft:gold_ingot',
      B: 'mcore:steel_ingot'
    }
  )

  //iron

  event.remove({ output: "minecraft:iron_helmet" })

  event.shaped(
    Item.of('minecraft:iron_helmet'),
    [
      'ABA',
      'A A',
    ],
    {
      A: 'minecraft:iron_ingot',
      B: 'minecraft:leather'
    }
  )

  event.remove({ output: "minecraft:iron_chestplate" })

  event.shaped(
    Item.of('minecraft:iron_chestplate'),
    [
      'A A',
      'ABA',
      'AAA'
    ],
    {
      A: 'minecraft:iron_ingot',
      B: 'minecraft:leather'
    }
  )

  event.remove({ output: "minecraft:iron_leggings" })

  event.shaped(
    Item.of('minecraft:iron_leggings'),
    [
      'ABA',
      'A A',
      'A A'
    ],
    {
      A: 'minecraft:iron_ingot',
      B: 'minecraft:leather'
    }
  )

  event.remove({ output: "minecraft:iron_boots" })

  event.shaped(
    Item.of('minecraft:iron_boots'),
    [
      'B B',
      'A A',
    ],
    {
      A: 'minecraft:iron_ingot',
      B: 'minecraft:leather'
    }
  )

  //leather

  event.remove({ output: "minecraft:leather_helmet" })

  event.shaped(
    Item.of('minecraft:leather_helmet'),
    [
      'ABA',
      'A A'
    ],
    {
      A: 'minecraft:leather',
      B: 'minecraft:iron_ingot'
    }
  )

  //turtle shell

  event.remove({ output: "minecraft:turtle_helmet" })

  event.shaped(
    Item.of('minecraft:turtle_helmet'),
    [
      'ABA',
      'ACA'
    ],
    {
      A: 'minecraft:iron_ingot',
      B: 'minecraft:scute',
      C: 'minecraft:glass'
    }
  )

  //copper lighter

  event.remove({ output: "minecraft:flint_and_steel" })

  event.shaped(
    Item.of('minecraft:flint_and_steel'),
    [
      'AB'
    ],
    {
      A: 'minecraft:copper_ingot',
      B: 'minecraft:flint'
    }
  )


  // Script wrote by AdversePond / MC7
  // patch the infinite gold/xp crystals bug where you could infinitely recycle gilded blackstone. You can still crush it, but you can no longer make it.
  event.remove({ output: "minecraft:gilded_blackstone" })
  event.remove({ id: "create:crushing/gilded_blackstone" })

  event.remove({ id: "create:bulk_haunting/ender_pearl" })  // ADDITION: Removing 10/18/2025 

  // resolves #31, conflict with create radars 
  event.remove({ id: "decorative_blocks:bar_panel" })
  event.shaped(
    Item.of("decorative_blocks:bar_panel", 4),
    [
      'AA',
      'AA'
    ],
    {
      A: 'minecraft:iron_bars'
    }
  )


  //Netherite balancing. Wrote by Onmod

  /*
  event.remove({ output: "minecraft:netherite_ingot" })
  event.remove({ output: "minecraft:netherite_nugget" })

  event.smelting('minecraft:netherite_ingot', 'minecraft:netherite_scrap')
  event.blasting('minecraft:netherite_ingot', 'minecraft:netherite_scrap')

  event.smelting('createdeco:netherite_nugget', 'overworld_netherite_ore:ancientdebrispiece')
  event.blasting('createdeco:netherite_nugget', 'overworld_netherite_ore:ancientdebrispiece')

  event.smelting('2x createdeco:netherite_nugget', 'overworld_netherite_ore:large_ancient_shard')
  event.blasting('2x createdeco:netherite_nugget', 'overworld_netherite_ore:large_ancient_shard')
  */
})


/*
    //Changes the recipe of the tacz gun workbench.
    event.shaped(
      Item.of('the_deep_void:refined_bismuth'),
      [
        'BAB',
        'ACA',
        'BAB'
      ],
      {
        A: 'the_deep_void:refined_onyx',
        B: 'mcore:titanium_ingot',
        C: 'the_deep_void:bismuth'
      }
    )
*/
// Removes the overpowered create netherless netherite recipe.
//event.remove({ id: 'create_netherless:netherite_fragment_by_crushing'})
//Removes gold and diamond armor. Edit: Why Pond? why?
/*
event.remove({ output: 'minecraft:diamond_helmet'})
event.remove({ output: 'minecraft:diamond_chestplate'})
event.remove({ output: 'minecraft:diamond_leggings'})
event.remove({ output: 'minecraft:diamond_boots'})
event.remove({ output: 'minecraft:golden_helmet'})
event.remove({ output: 'minecraft:golden_chestplate'})
event.remove({ output: 'minecraft:golden_leggings'})
event.remove({ output: 'minecraft:golden_boots'})
*/
// adds gun components. tacz recipes have been changed in their config.
// adds small springs, however appears to be bugged. Will fix in a later release.
// event.recipes.createSequencedAssembly([
//   'kubejs:small_spring'
//  ], 'kubejs:iron_wire',
//  [
//  event.recipes.createCutting('kubejs:incomplete_small_spring', 'kubejs:incomplete_small_spring').processingTime(50)
//   ]).transitionalItem('kubejs:incomplete_small_spring').loops(6)
//reinforced barrel beginnings
// event.recipes.createSequencedAssembly([
//  'kubejs:cw_additions:reinforced_barrel'
//  ], 'marbledsapi:hardened_steel_ingot',
//  [
//  event.recipes.createCutting('cw_additions:reinforced_barrel', 'cw_additions:reinforced_barrel').processingTime(100)
//  ]).transitionalItem('cw_additions:reinforced_barrel').loops(3)
//rb end - CURRENTLY IS THE ENTIRE RECIPE
/*
event.recipes.createSequencedAssembly([
 'cw_additions:reinforced_barrel'
], 'cw_additions:reinforced_barrel',
[
event.recipes.createCutting('cw_additions:reinforced_barrel', 'cw_additions:reinforced_barrel').processingTime(100)
event.recipes.createCutting('cw_additions:reinforced_barrel', 'cw_additions:reinforced_barrel').processingTime(100),
event.recipes.createFilling('cw_additions:reinforced_barrel', ['cw_additions:reinforced_barrel', Fluid.of('minecraft:lava', 250)])
]).transitionalItem('cw_additions:reinforced_barrel').loops(3)
//recipe for rubber sheet: 250 mb liquid rubber + mold = ~~rubber sheet + mold~~ FILLED MOLD
event.recipes.createFilling('kubejs:filled_rubber_mold', ['cw_additions:rubber_mold', Fluid.of('kubejs:molten_rubber', 250)])
//recipe for liquid rubber
event.recipes.createMixing(Fluid.of('kubejs:molten_rubber', 50), 'cw_additions:rubber_scrap').heated()
//removal of all recipes from spore
event.remove({ mod: 'spore' })
// hardened steel recipe
event.recipes.createCompacting('marbledsapi:hardened_steel_ingot', [Fluid.of('minecraft:lava', 150), 'minecraft:netherite_scrap', 'minecraft:netherite_scrap', 'cw_additions:gunsteel', 'cw_additions:gunsteel', 'cw_additions:gunsteel']).superheated()
// gunsteel recipe
event.recipes.createCompacting('cw_additions:gunsteel', ['pointblank:gunmetal_nugget', 'pointblank:gunmetal_nugget', 'pointblank:gunmetal_nugget', 'pointblank:gunmetal_nugget', 'pointblank:gunmetal_nugget', 'create:zinc_nugget', 'create:zinc_nugget', 'create:zinc_nugget', 'create:zinc_nugget', 'minecraft:flint' ]).heated()
// buffed cinder flour recipe
event.recipes.createCrushing(['create:cinder_flour', 'create:cinder_flour', 'create:cinder_flour', Item.of('create:cinder_flour').withChance(0.75), Item.of('create:cinder_flour').withChance(0.5), Item.of('create:cinder_flour').withChance(0.1), Item.of('create:cinder_flour').withChance(0.1)], 'minecraft:netherrack')
// disable old lava recipe, buffed lava recipe
event.remove({ id: 'create:mixing/lava_from_cobble'})
event.recipes.createMixing(Fluid.of('minecraft:lava', 100), '#forge:cobblestone').superheated().id('more_lava_from_cobble')
// MA rebalance: planned !
*/

// END OF RECIPE TWEAKS



// BEGINNING OF ITEM CODE - PLEASE LEAVE UNDISTURBED - IS FUNCTIONAL
/*
ItemEvents.rightClicked( 'kubejs:filled_rubber_mold', event => 
{
  event.item.count--
  event.player.give('cw_additions:rubber_sheet')
  event.player.give('cw_additions:rubber_mold')
})
//END OF ITEM CODE
*/

