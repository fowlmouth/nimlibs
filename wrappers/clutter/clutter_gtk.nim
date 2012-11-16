import clutter, gtk2, glib2

when defined(Linux):
  const libname = "libclutter-gtk-1.0.so.0"

type
  
  PGtkActor* = ptr TGtkActor
  TGtkActor* {.pure.} = object of clutter.TActor
  
  PGtkWindow* = ptr TGtkWindow
  TGtkWindow* {.pure.} = object of TActor

  PGtkEmbed* = ptr TGtkEmbed
  TGtkEmbed* {.pure.} = object of TActor

#GType         gtk_clutter_actor_get_type          (void) G_GNUC_CONST;
#ClutterActor *gtk_clutter_actor_new               (void);

#ClutterActor *gtk_clutter_actor_new_with_contents (GtkWidget       *contents);
#GtkWidget *   gtk_clutter_actor_get_contents      (GtkClutterActor *actor);
#GtkWidget *   gtk_clutter_actor_get_widget        (GtkClutterActor *actor);

{.push: cdecl, dynlib: LibName.}

proc gtk_actor_get_type*(): GType {.importc: "gtk_clutter_actor_get_type".}
proc newGTKActor_c*(): PActor {.importc: "gtk_clutter_actor_new".}
proc newGTKActor_c*(contents: gtk2.PWidget): PActor {.
  importc: "gtk_clutter_actor_new_with_contents".}

proc getContents*(actor: PGtkActor): PWidget {.importc:"gtk_clutter_actor_get_contents".}
proc gtkGetWidget*(actor: PGtkActor): PWidget {.importc: "gtk_clutter_actor_get_widget".}
#GTK_CLUTTER_TYPE_ACTOR          (gtk_clutter_actor_get_type ())
#GTK_CLUTTER_ACTOR(o)            (G_TYPE_CHECK_INSTANCE_CAST ((o), GTK_CLUTTER_TYPE_ACTOR, GtkClutterActor))



proc gtk_window_get_type*(): GType  {.importc: "gtk_clutter_window_get_type".}
proc newGTKWindow*(): PWidget {.importc: "gtk_clutter_window_new".}
proc getStage*(window: PGtkWindow): PActor {.importc: "gtk_clutter_window_get_stage".}
#


proc gtk_embed_get_type*(): GType {.importc: "gtk_clutter_embed_get_type".}
proc newGTKembed*(): PWidget {.importc: "gtk_clutter_embed_new".}
proc getStage*(embed: PGtkEmbed): PActor {.importc: "gtk_clutter_embed_get_stage".}




{.pop.}

template GTK_CLUTTER_WINDOW*(some: PActor): expr = cast[PGtkClutterWindow](
  G_TYPE_CHECK_INSTANCE_CAST(some, gtk_window_get_type()))

##define GTK_CLUTTER_TYPE_WINDOW          (gtk_clutter_window_get_type ())
##define GTK_CLUTTER_WINDOW(o)            (G_TYPE_CHECK_INSTANCE_CAST ((o), GTK_CLUTTER_TYPE_WINDOW, GtkClutterWindow))
##define GTK_CLUTTER_IS_WINDOW(o)         (G_TYPE_CHECK_INSTANCE_TYPE ((o), GTK_CLUTTER_TYPE_WINDOW))
##define GTK_CLUTTER_WINDOW_CLASS(k)      (G_TYPE_CHECK_CLASS_CAST ((k), GTK_CLUTTER_TYPE_WINDOW, GtkClutterWindowClass))
##define GTK_CLUTTER_IS_WINDOW_CLASS(k)   (G_TYPE_CHECK_CLASS_TYPE ((k), GTK_CLUTTER_TYPE_WINDOW))
##define GTK_CLUTTER_WINDOW_GET_CLASS(o)  (G_TYPE_INSTANCE_GET_CLASS ((o), GTK_CLUTTER_TYPE_WINDOW, GtkClutterWindowClass))
#


template GTK_CLUTTER_ACTOR*(some: PActor): expr = cast[PGtkActor](
  G_TYPE_CHECK_INSTANCE_CAST(some, gtk_actor_get_type()))

proc newGTKActor*(): PGtkActor {.inline.} = GTK_CLUTTER_ACTOR(newGTKActor_c())
proc newGTKActor*(cnt: gtk2.PWidget): PGtkActor{.inline.}=GTK_CLUTTER_ACTOR(newGTKActor(cnt))

# gtk-clutter-actor.h: Gtk widget ClutterActor
# 
#  Copyright (C) 2009 Red Hat, Inc
#  Copyright (C) 2010 Intel Corp
# 
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
# 
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
# 
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library. If not see <http://www.fsf.org/licensing>.
# 
#  Authors:
#    Alexander Larsson <alexl@redhat.com>
#    Emmanuele Bassi <ebassi@linux.intel.com>
# 


#G_BEGIN_DECLS
#
##define 
##define 
##define GTK_CLUTTER_IS_ACTOR(o)         (G_TYPE_CHECK_INSTANCE_TYPE ((o), GTK_CLUTTER_TYPE_ACTOR))
##define GTK_CLUTTER_ACTOR_CLASS(k)      (G_TYPE_CHECK_CLASS_CAST ((k), GTK_CLUTTER_TYPE_ACTOR, GtkClutterActorClass))
##define GTK_CLUTTER_IS_ACTOR_CLASS(k)   (G_TYPE_CHECK_CLASS_TYPE ((k), GTK_CLUTTER_TYPE_ACTOR))
##define GTK_CLUTTER_ACTOR_GET_CLASS(o)  (G_TYPE_INSTANCE_GET_CLASS ((o), GTK_CLUTTER_TYPE_ACTOR, GtkClutterActorClass))
#

discard """proc gtk_clutter_actor_get_type*(): GType
proc gtk_clutter_actor_new*(): ptr ClutterActor
proc gtk_clutter_actor_new_with_contents*(contents: ptr GtkWidget): ptr ClutterActor"""
#G_END_DECLS


#
##define GTK_CLUTTER_TYPE_EMBED          (gtk_clutter_embed_get_type ())
##define GTK_CLUTTER_EMBED(o)            (G_TYPE_CHECK_INSTANCE_CAST ((o), GTK_CLUTTER_TYPE_EMBED, GtkClutterEmbed))
##define GTK_CLUTTER_IS_EMBED(o)         (G_TYPE_CHECK_INSTANCE_TYPE ((o), GTK_CLUTTER_TYPE_EMBED))
##define GTK_CLUTTER_EMBED_CLASS(k)      (G_TYPE_CHECK_CLASS_CAST ((k), GTK_CLUTTER_TYPE_EMBED, GtkClutterEmbedClass))
##define GTK_CLUTTER_IS_EMBED_CLASS(k)   (G_TYPE_CHECK_CLASS_TYPE ((k), GTK_CLUTTER_TYPE_EMBED))
##define GTK_CLUTTER_EMBED_GET_CLASS(o)  (G_TYPE_INSTANCE_GET_CLASS ((o), GTK_CLUTTER_TYPE_EMBED, GtkClutterEmbedClass))
#


when ismainmodule:
  proc on_button_clicked(button: PButton; userdata: gpointer): gboolean {.cdecl.}=
    echo "clicked. neat huh?"
    return true


  proc local_quit(widget: pWidget, data: pgpointer){.cdecl.} = 
    main_quit()

  discard initclutter(nil, nil)
  echo "init"
  var gtkwin = gtk2.window_new(gtk2.WINDOW_TOPLEVEL)
  var vbox = gtk2.vbox_new(false, 6)
  add(CONTAINER(gtkwin), vbox)
  show vbox
  
  var button = button_new("Change Color")
  pack_end(vbox, button, FALSE, FALSE, 0)
  show(button)
  
  discard signal_connect(`OBJECT`(button), "clicked", SIGNAL_FUNC(on_button_clicked), nil)

  ## /* Stop the application when the window is closed: */
  discard signal_connect(`OBJECT`(gtkwin), "hide", SIGNAL_FUNC(local_quit), nil)

  ## /* Create the clutter widget: */
  var clutter_widget = newGTKembed ();
  pack_start (BOX (vbox), clutter_widget, TRUE, TRUE, 0)
  show (clutter_widget);
  
  gtk2.main()
  
  
  
  
