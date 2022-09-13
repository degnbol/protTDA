#!/usr/bin/env python3
cmd.remove("resn hoh")
objs = cmd.get_object_list()
for other in objs[1:]:
    cmd.align(objs[0], other)
    cmd.hide('cartoon', other)
    cmd.show('ribbon', other)
    cmd.color('grey40', other)

