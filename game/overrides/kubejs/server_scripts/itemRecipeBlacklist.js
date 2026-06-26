//Script created by MC7 / Adversepond, modified by Onmod

// Last modified 10/18/2025, Pond.

// Modification policy: please comment "ADDITION: [Description]" next to all changes you made when you recieved the file. 
// Please remove all such "ADDITION: [D]" messages you inherit.
// Ignore the above if you are not Pond or OnMod. If you must edit this file, please report changes to both of us in a thread.

global.bannedItems = [
  "the_deep_void:void_cloak_chestplate",
  "the_deep_void:void_core",
  "the_deep_void:rotten_dart",
  "the_deep_void:stalker_treat",
  "the_deep_void:void_dagger",
  "the_deep_void:void_pendant",
  "the_deep_void:licker_hook",
  "the_deep_void:grim_scythe",
  "the_deep_void:voidrium_boots",
  "the_deep_void:voidrium_leggings",
  "the_deep_void:voidrium_chestplate",
  "the_deep_void:voidrium_helmet",
  "the_deep_void:forbidden_tome",

// ADDITIONS


// removing flesh items
  "the_deep_void:flesh_bricks", 
  "the_deep_void:flesh_brick_stairs", 
  "the_deep_void:flesh_brick_slab", 
  "the_deep_void:teeth_trap", 
  "the_deep_void:pustulent_flesh_bricks", 
  "the_deep_void:pustulent_flesh_brick_stairs", 
  "the_deep_void:pustulent_flesh_brick_slab",
  "the_deep_void:flesh_brick_wall",  
  "the_deep__void:flesh_block",
  "the_deep__void:pustulent_flesh_block",
  "the_deep__void:pus_flower",
  "the_deep_void:pus_sack",
  "the_deep__void:pus_ball",


// removing random things that I don't know how to categorize

  "the_deep_void:corpse",
  "the_deep_void:wall_corpse",
  "the_deep_void:stalker_scythe_claw",
  "the_deep_void:mourner_hide",
  "the_deep_void:forgotten_token",
  "the_deep_void:onyx_needle",
  "the_deep_void:licker_spawn_egg",
  "the_deep_void:bloody_tongue",
  "the_deep_void:rotten_tongue_hook",
  "the_deep_void:void_matter", //?
  "the_deep_void:eye_lens",
  "the_deep_void:eye_shield",
  "the_deep_void:devourer_tendril",
  "the_deep_void:devourer_shield",
  "the_deep_void:devourer_hook",
  "the_deep_void:lavendite_devourer_hook",
  "the_deep_void:rotten_bone",

// removing spawn eggs

  "the_deep_void:mourner_spawn_egg",
  "the_deep_void:fool_eater_spawn_egg",
  "the_deep_void:damned_spawn_egg",
  "the_deep_void:stalker_spawn_egg",
  "the_deep_void:nightmare_spawn_egg",
  "the_deep_void:rotten_corpse_spawn_egg",
  "the_deep_void:hallucination_spawn_egg",
  "the_deep_void:abductor_spawn_egg",
  "the_deep_void:lurker_spawn_egg",
  "the_deep_void:gravekeeper_spawn_egg",
  "the_deep_void:roamer_spawn_egg",
  "the_deep_void:spore_spewer_spawn_egg",
  "the_deep_void:flesh_cube_spawn_egg",
  "the_deep_void:devourer_spawn_egg",
  "the_deep_void:wanderer_spawn_egg",
 
// removing pure lavendite gear
  "the_deep_void:lavendite_shield",
  "the_deep_void:lavendite_boots", // may be erroneous
  "the_deep_void:lavendite_leggings",
  "the_deep_void:lavendite_chestplate",
  "the_deep_void:lavendite_helmet",
  "the_deep_void:lavendite_sword",

// removing lavendite enhanced gear
  "the_deep_void:lavendite_wooden_sword",
  "the_deep_void:lavendite_stone_sword",
  "the_deep_void:lavendite_bone_sword",
  "the_deep_void:lavendite_onyx_sword",
  "the_deep_void:lavendite_golden_sword",
  "the_deep_void:lavendite_iron_sword",
  "the_deep_void:lavendite_diamond_sword",
  "the_deep_void:lavendite_netherite_sword",

// removing bone gear
  "the_deep_void:bone_sword",
  "the_deep_void:bone_pickaxe",
  "the_deep_void:bone_axe",
  "the_deep_void:bone_shovel",
  "the_deep_void:bone_hoe",

// removing rotten bone gear
  "the_deep_void:rotten_bone_armor_helmet",
  "the_deep_void:rotten_bone_armor_chestplate",
  "the_deep_void:rotten_bone_armor_leggings",
  "the_deep_void:rotten_bone_armor_boots",
  "the_deep_void:rotten_wooden_sword",
  "the_deep_void:rotten_stone_sword",
  "the_deep_void:rotten_bone_sword",
  "the_deep_void:rotten_onyx_sword",
  "the_deep_void:rotten_golden_sword",
  "the_deep_void:rotten_iron_sword",
  "the_deep_void:rotten_diamond_sword",
  "the_deep_void:rotten_netherite_sword",
  "the_deep_void:rotten_sickle", 

  // removing grim gear and gem
  "the_deep__void:grim_gem",
  "the_deep_void:grim_rotten_bone_armor_helmet",
  "the_deep_void:grim_rotten_bone_armor_chestplate",
  "the_deep_void:grim_rotten_bone_armor_leggings",
  "the_deep_void:grim_rotten_bone_armor_boots",

  //removing alexs mobs stuff
  "alexsmobs:transmutation_table",
  "alexsmobs:shattered_dimensional_carver",
  "alexsmobs:dimensional_carver",
  "alexsmobs:shield_of_the_deep",
  "alexsmobs:stink_ray",
  "alexsmobs:tendon_whip", 
  "alexmobs:elastic_tendon", 
  "alexmobs:dropbear_claw", 


]
ServerEvents.tags('item', event => {
  global.bannedItems.forEach(bannedItem => {
    // hide from recipe viewers
    event.add('c:hidden_from_recipe_viewers', bannedItem)
  })
})

global.itemAsInputRecipeBlacklist = [
  "create_netherless:netherite_fragment"
];
global.recipeBlacklist = [
  "immersive_weathering:iron_ingot_from_clean_block",
  "immersive_weathering:iron_ingot_from_clean_block_blasting",
  "immersive_weathering:iron_ingot_from_exposed_block",
  "immersive_weathering:iron_ingot_from_exposed_block_blasting",
  "immersive_weathering:iron_ingot_from_rusted_block",
  "immersive_weathering:iron_ingot_from_rusted_block_blasting",
  "immersive_weathering:iron_ingot_from_weathered_block",
  "immersive_weathering:iron_ingot_from_weathered_block_blasting",
  "the_deep_void:refined_bismuth",
  "minecraft:gunpowder",
  "marbledsfirstaid:curative_pills",
  "create:splashing/gravel", //recipe for infinite iron
  "create:splashing/red_sand", //recipe for infinite gold
  "create_netherless:ender_pearl_by_haunting" // ADDITION: resolves an item on OnMod's ToDoist
];

ServerEvents.recipes(event => {
  console.log(global.recipeBlacklist) // not relevant to the code immediately below
  global.bannedItems.forEach(element => {
    event.remove({ output: element })  //removes recipes that create the element (banned items)
  }
  );
  global.itemAsInputRecipeBlacklist.forEach(element => {
    event.remove({ input: element }) //removes recipes in which the element is used as an ingredient of the created item
  }
  );
  global.recipeBlacklist.forEach(element => {
    event.remove(element); //removes recipes specified in recipeBlacklist
  }
  );

  // Removes gunpowder recipes from tacz and the deep void
  event.remove({id: 'tacz:gunpowder'});
  event.remove({id: 'the_deep_void:gunpowder'});

  //Script written by MC7 / AdversePond
 event.shaped(
  Item.of('kubejs:sweet_berry_crate', 1),
  [
    'AAA',
    'AAA', 
    'AAA'
  ],
  {
    A: 'minecraft:sweet_berries',
  }
)

event.shaped(
  Item.of('minecraft:sweet_berries', 9),
  [
    'A',
  ],
{
    A: 'kubejs:sweet_berry_crate',
}
)

 //Script written by Onmod, adapted from MC7 / AdversePond
 event.shaped(
  Item.of('kubejs:gunpowder_barrel', 1),
  [
    'AAA',
    'AAA', 
    'AAA'
  ],
  {
    A: 'minecraft:gunpowder',
  }
)

event.shaped(
  Item.of('minecraft:gunpowder', 9),
  [
    'A',
  ],
{
    A: 'kubejs:gunpowder_barrel',
}
)
  
  
  /*
  // NOTE: UNUSED CODE (FOR REFERENCE ONLY, DO NOT ENABLE)

  event.remove('create_netherless:netherite_fragment_by_crushing') //deletion & recreation of create mod blackstone crushing recipe to remove netherite fragment
  event.custom({
    "type": "create:crushing",
    "ingredients": [
      {
        "item": "minecraft:blackstone"
      }
    ],
    "results": [
      {
        "item": "coal",
        "count": 1,
        "chance": 0.5
      }
    ],
    "processingTime": 250
  })


//replaces k turret titanium ingot with mcore titanium ingot in certain recipes unnaccounted for by previous code.   
event.replaceInput({id:'k_turrets:gauss_bullet'},'k_turrets:titanium_ingot','minecraft:obsidian'); //making gause bullets require mcore titanium would be absurdly expensive.
event.replaceInput({id:'k_turrets:reloader'},'k_turrets:titanium_ingot','mcore:titanium_ingot');
event.replaceInput({id:'k_turrets:wrench'},'k_turrets:titanium_ingot','mcore:titanium_ingot');

//K turrets removed
 ServerEvents.tags('item',event=>{
    //removes k_turret's titanium ingot from the titanium tags for the purpose of removing it from recipes that use any titanium. this is needed because simply doing "event.remove({input: k_turret:titanium_ingot})" would unfortunately delete the entirety of any recipe that includes it
    event.remove('forge:ingots/titanium','k_turrets:titanium_ingot')
    event.remove('forge:titanium','k_turrets:titanium_ingot')
})


IN-PROGRESS CODE FOR LOGGING THE LOCATION OF PVP DEATHS. CURRENTLY WOULD JUST LOG TO CONSOLE, OPTIMALLY WE WANT THE RESULTS PRINTED IN A WAY THAT MAKES THEM SHOW UP IN #server-logs CHANNEL. WOULD ALSO PUT IN A SEPERATE SCRIPT FILE AS WELL SINCE ITS NOT RECIPE RELATED
EntityEvents.death('minecraft:player',e=>{
  let killerName = e.source.getPlayer().username;
  let victimName = e.getEntity().username;

  let killerX = e.source.getPlayer().x;
  let killerY = e.source.getPlayer().y;
  let killerZ = e.source.getPlayer().z;
  let victimX = e.getEntity().x;
  let victimY = e.getEntity().y;
  let victimZ = e.getEntity().z;

  let killerPos = killerX + " " + killerY + " " + killerZ;
  let victimPos = victimX + " " + victimY + " " + victimZ;
  console.log("[KILLLOG: Killer] " + killerName + ": " + killerPos);
  console.log("[KILLLOG: Victim] " + victimName + ": " + victimPos);
})

//===SPECIAL CASES====//

  //K turrets removed
  //event.remove([{ type: 'minecraft:smelting', output: 'k_turrets:titanium_ingot' }, { type: 'minecraft:blasting', output: 'k_turrets:titanium_ingot' }])

*/

})

//For all code related to k_turret titanium in this script: even though the ore is disabled from generation if disabledOres.js is running, it still needs to be removed from JEI menus as well to prevent confusion among new players