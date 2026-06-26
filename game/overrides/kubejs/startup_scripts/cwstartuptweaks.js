console.log('CW Tweaks Startup scripts successfully loaded.')

StartupEvents.registry('block', event => {

  // Script written by MC7 / AdversePond. 
  // Texture work done by Keerdm.
  event.create('sweet_berry_crate')
    .displayName('Sweet Berry Crate')
    .soundType('wood')
    .hardness(1.0)
    .resistance(1.0)
    .tagBlock('minecraft:mineable/axe')

    .textureAll('kubejs:block/sb_side')
    .texture('up', 'kubejs:block/sb_top')
    .texture('down', 'kubejs:block/sb_bottom')

  //Script written by Onmod, adapted from MC7 / AdversePond.
  //Texture work done by ActiveRadar and Onmod, partially adapted from texture by Mojang Studios
  event.create('gunpowder_barrel')
    .displayName('Gunpowder Barrel')
    .soundType('wood')
    .hardness(1.0)
    .resistance(1.0)
    .tagBlock('minecraft:mineable/axe')

    .textureAll('kubejs:block/gb_side1')
    .texture('up', 'kubejs:block/gb_top')
    .texture('down', 'kubejs:block/gb_bottom')
});

StartupEvents.registry('item', event => {
  
  //Script wrote by Onmod, textures done by ActiveRadar
  event.create('circuit_board')
    .displayName('Circuit Board')
    .texture('kubejs:item/cw_circuit_board')
    .tooltip(['A piece of tech used in some advanced recipes'])
    .rarity('uncommon')

  event.create('advanced_circuit_board')
    .displayName('Advanced Circuit Board')
    .texture('kubejs:item/advanced_cw_circuit_board')
    .tooltip(['A piece of tech used in some highly advanced recipes'])
    .rarity('rare')

     //Script wrote by Onmod, textures done by MarbledNull
    event.create('cables')
    .displayName('Cables')
    .texture('kubejs:item/cables')
    .tooltip(['A collection of wires that might be useful for something...'])
    .rarity('uncommon')

    event.create('defib')
    .displayName('Defibrillator Casing')
    .texture('kubejs:item/defib_casing')
    .tooltip(['A key component in the crafting of the defibrillator. Obviously.'])
    .rarity('uncommon')

    event.create('shock')
    .displayName('Shock Component')
    .texture('kubejs:item/shock_component')
    .tooltip(['Quite a shocking piece of tech that might be useful for... shocking.'])
    .rarity('uncommon')
});

//Script inspired from KCtops6, wrote by Onmod
ItemEvents.modification(event => {
  event.modify('minecraft:netherite_helmet', item => {
  //  item.maxDamage = 
    item.armorProtection = 4
   // item.armorToughness = 
    item.armorKnockbackResistance = .4
  })

  event.modify('minecraft:netherite_chestplate', item => {
  //  item.maxDamage = 
    item.armorProtection = 9
   // item.armorToughness = 
    item.armorKnockbackResistance = .4
  })

  event.modify('minecraft:netherite_leggings', item => {
  //  item.maxDamage = 
    item.armorProtection = 7
   // item.armorToughness = 
    item.armorKnockbackResistance = .4
  })

  event.modify('minecraft:netherite_boots', item => {
  //  item.maxDamage = 
    item.armorProtection = 4
   // item.armorToughness = 
    item.armorKnockbackResistance = .4
  })

})

  

  