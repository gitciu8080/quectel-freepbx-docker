#!/bin/bash 

mkdir -p yealink/ext yealink/cm

# 分机转 XML：Yealink
curl -fSL --connect-timeout 30 https://raw.githubusercontent.com/sorvani/freepbx-helper-scripts/master/Extensions_to_Yealink_AddressBook/ylab.php -o yealink/ext/index.php


# 通讯录管理器转 XML：Yealink
curl -fSL --connect-timeout 30 https://raw.githubusercontent.com/sorvani/freepbx-helper-scripts/master/ContactManager_to_Yealink_AddressBook/cm_to_yl_ab.php -o yealink/cm/index.php
