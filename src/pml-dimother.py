#!/usr/bin/env python3
cmd.remove("resn hoh")
for name in cmd.get_object_list()[1:]:
    cmd.hide('cartoon', name)
    cmd.show('ribbon', name)
    cmd.color('grey40', name)

