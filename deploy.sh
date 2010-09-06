#!/bin/sh

rm -rf "${WOW_BETA_ADDON_DIR}Dominos"
rm -rf "${WOW_BETA_ADDON_DIR}Dominos_Cast"
rm -rf "${WOW_BETA_ADDON_DIR}Dominos_Config"
rm -rf "${WOW_BETA_ADDON_DIR}Dominos_Roll"
rm -rf "${WOW_BETA_ADDON_DIR}Dominos_Totems"
rm -rf "${WOW_BETA_ADDON_DIR}Dominos_XP"

cp -r Dominos "${WOW_BETA_ADDON_DIR}"
cp -r Dominos_Config "${WOW_BETA_ADDON_DIR}"
cp -r Dominos_Cast "${WOW_BETA_ADDON_DIR}"
cp -r Dominos_Roll "${WOW_BETA_ADDON_DIR}"
cp -r Dominos_Totems "${WOW_BETA_ADDON_DIR}"
cp -r Dominos_XP "${WOW_BETA_ADDON_DIR}"

cp README.textile "${WOW_BETA_ADDON_DIR}Dominos"

cp LICENSE "${WOW_BETA_ADDON_DIR}Dominos"
cp LICENSE "${WOW_BETA_ADDON_DIR}Dominos_Cast"
cp LICENSE "${WOW_BETA_ADDON_DIR}Dominos_Config"
cp LICENSE "${WOW_BETA_ADDON_DIR}Dominos_Roll"
cp LICENSE "${WOW_BETA_ADDON_DIR}Dominos_Totems"
cp LICENSE "${WOW_BETA_ADDON_DIR}Dominos_XP"