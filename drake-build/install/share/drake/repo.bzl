# -*- mode: python -*-
# vi: set ft=python :


def _call_drake_impl(*args):  # Akin to a forward declaration.
    _drake_impl(*args)

drake_repository = repository_rule(
    implementation = _call_drake_impl,
    local = True,
    doc = """
Declares the @drake repository based on an installed Drake binary image.

This enables downstream BUILD files to refer to Drake targets such as
@drake//bindings/pydrake even when using precompiled Drake releases.

Only a limited number of targets are supported, currently only:
- @drake//bindings/pydrake

For an example of proper use, see
https://github.com/RobotLocomotion/drake-external-examples/tree/master/drake_bazel_installed
""",
)

def _drake_impl(repo_ctx):
    # Obtain the root of the @drake_loader repository (i.e., wherever this
    # repo.bzl file came from).
    loader_workspace = repo_ctx.path(Label("//:WORKSPACE")).dirname

    # If the loader came from an http_archive of a Drake binary release, its
    # workspace will have paths like drake/lib/..., drake/share/..., etc.
    # If the loader came from a new_local_repository on disk, the `path = ...`
    # provided to new_local_repository might already incorporate the "drake"
    # prefix so have paths like lib/..., share/..., etc.  We'll automatically
    # detect which case is in effect.
    for prefix in [
        loader_workspace,
        loader_workspace.get_child("drake"),
        None,
    ]:
        if prefix == None:
            fail("Could not find drake sentinel under {}".format(
                loader_workspace,
            ))
        share = prefix.get_child("share")
        share_drake = share.get_child("drake")
        sentinel = share_drake.get_child(".drake-find_resource-sentinel")
        if sentinel.exists:
            break

    # Sanity check ${prefix}.
    required_files = [
        "include/drake/common/drake_assert.h",
        "lib/libdrake.so",
    ]
    for required_file in required_files:
        if not repo_ctx.path(str(prefix) + "/" + required_file).exists:
            fail("The drake install prefix {} is missing file {}".format(
                prefix,
                required_file,
            ))

    # Symlink our libraries into the repository.  We can use any path for
    # these, since our BUILD rules will declare new names for everything,
    # unrelated to their physical structure here.
    repo_ctx.symlink(prefix.get_child("lib"), ".lib")

    # Create the stub BUILD files.  (During development, these live at
    # drake/tools/install/bazel/drake**.BUILD.bazel in the source tree.)
    for path, body in _BUILD_FILE_CONTENTS.items():
        repo_ctx.file(path, content = body, executable = False)

    # Symlink the data resources into the repository.  These must exactly match
    # a Drake source tree's physical structure, since we cannot easily alter
    # the path for runfiles via our BUILD files.
    for relpath in _MANIFEST["runfiles"]["drake"]:
        repo_ctx.symlink(str(share_drake) + "/" + relpath, relpath)

    # Symlink all drake LCM types to this repository's root package, since it
    # should be named `drake` (see bazelbuild/bazel#3998).
    if repo_ctx.name != "drake":
        print("WARNING: Drake LCM types will not be importable via `drake` " +
              "if this repository is not named `drake`.")
    python_site_packages_relpath = _MANIFEST["python_site_packages_relpath"]
    drake_lcmtypes_package = "." + python_site_packages_relpath + "/drake"
    for relpath in _MANIFEST["lcmtypes_drake_py"]:
        repo_ctx.symlink(drake_lcmtypes_package + "/" + relpath, relpath)

    # Emit the manifest for later loading.
    manifest_bzl = "MANIFEST = " + struct(**_MANIFEST).to_json()
    repo_ctx.file(".manifest.bzl", content = manifest_bzl, executable = False)

_BUILD_FILE_CONTENTS = {
  "BUILD.bazel": r"""
# -*- mode: python -*-
# vi: set ft=python :

load("@rules_python//python:defs.bzl", "py_library")
load("//:.manifest.bzl", "MANIFEST")

package(default_visibility = ["//:__subpackages__"])

_DRAKE_RUNFILES = MANIFEST["runfiles"]["drake"]

_PYTHON_SITE_PACKAGES_RELPATH = MANIFEST["python_site_packages_relpath"]

_DRAKE_ROOT_PACKAGE_RUNFILES = [x for x in _DRAKE_RUNFILES if "/" not in x]

_EXPECTED_DRAKE_RUNFILES_PACKAGES = [
    "common",
    "examples",
    "manipulation",
]

_COVERED_DRAKE_RUNFILES = _DRAKE_ROOT_PACKAGE_RUNFILES + [
    x
    for x in _DRAKE_RUNFILES
    if any([
        x.startswith(package + "/")
        for package in _EXPECTED_DRAKE_RUNFILES_PACKAGES
    ])
]

(len(_COVERED_DRAKE_RUNFILES) == len(_DRAKE_RUNFILES)) or fail(
    "EXPECTED_DRAKE_RUNFILES_PACKAGES {} did not cover {}".format(
        _EXPECTED_DRAKE_RUNFILES_PACKAGES,
        _DRAKE_RUNFILES,
    ),
)

filegroup(
    name = ".installed_runfiles",
    data = _DRAKE_ROOT_PACKAGE_RUNFILES,
)

filegroup(
    name = ".all_runfiles",
    data = [
        "//:.installed_runfiles",
    ] + [
        "//{}:.installed_runfiles".format(x)
        for x in _EXPECTED_DRAKE_RUNFILES_PACKAGES
    ],
)

# TODO(jwnimmer-tri) Use the correct cc_import phrasing, then mark this public.
filegroup(
    name = ".drake_shared_library",
    data = glob([
        ".lib/*.so",
        ".lib/*.so.*",
    ]),
)

_IMPORT = "." + _PYTHON_SITE_PACKAGES_RELPATH

# N.B. This is not a standalone Python library.
# TODO(eric.cousineau): Expose this as an alias
# `@drake//lcmtypes:lcmtypes_drake_py` when it can only depend on specific
# parts of the runfiles (not all of pydrake).
py_library(
    name = ".lcmtypes_drake_py",
    srcs = glob(["*.py"]),
)

py_library(
    name = ".pydrake",
    srcs = glob(include = [
        _IMPORT + "/**/*.py",
    ]),
    data = glob(include = [
        _IMPORT + "/**/*.so",
    ]) + [
        ":.all_runfiles",
        ":.drake_shared_library",
    ],
    deps = [
        ":.lcmtypes_drake_py",
    ],
    imports = [
        _IMPORT,
    ],
)

""",
  "bindings/pydrake/BUILD.bazel": r"""
# -*- mode: python -*-
# vi: set ft=python :

# This is the @drake//bindings/pydrake package.

alias(
    name = "pydrake",
    actual = "//:.pydrake",
    visibility = ["//visibility:public"],
)

""",
  "common/BUILD.bazel": r"""
# -*- mode: python -*-
# vi: set ft=python :

# This is the @drake//common package.

load("//:.manifest.bzl", "MANIFEST")

package(default_visibility = ["//:__subpackages__"])

_subdir = "common/"

_runfiles = [
    x[len(_subdir):]
    for x in MANIFEST["runfiles"]["drake"]
    if x.startswith(_subdir)
]

filegroup(
    name = ".installed_runfiles",
    data = _runfiles,
)

""",
  "examples/BUILD.bazel": r"""
# -*- mode: python -*-
# vi: set ft=python :

# This is the @drake//examples package.

load("//:.manifest.bzl", "MANIFEST")

package(default_visibility = ["//:__subpackages__"])

_subdir = "examples/"

_runfiles = [
    x[len(_subdir):]
    for x in MANIFEST["runfiles"]["drake"]
    if x.startswith(_subdir)
]

filegroup(
    name = ".installed_runfiles",
    data = _runfiles,
)

""",
  "manipulation/BUILD.bazel": r"""
# -*- mode: python -*-
# vi: set ft=python :

# This is the @drake//manipulation package.

load("//:.manifest.bzl", "MANIFEST")

package(default_visibility = ["//:__subpackages__"])

_subdir = "manipulation/"

_runfiles = [
    x[len(_subdir):]
    for x in MANIFEST["runfiles"]["drake"]
    if x.startswith(_subdir)
]

filegroup(
    name = ".installed_runfiles",
    data = _runfiles,
)

""",
}


_MANIFEST = {"lcmtypes_drake_py":["__init__.py","lcmt_acrobot_u.py","lcmt_acrobot_x.py","lcmt_acrobot_y.py","lcmt_allegro_command.py","lcmt_allegro_status.py","lcmt_body_acceleration.py","lcmt_body_motion_data.py","lcmt_body_wrench_data.py","lcmt_call_python.py","lcmt_call_python_data.py","lcmt_constrained_values.py","lcmt_contact_information.py","lcmt_contact_results_for_viz.py","lcmt_desired_body_motion.py","lcmt_desired_centroidal_momentum_dot.py","lcmt_desired_dof_motions.py","lcmt_drake_signal.py","lcmt_foot_flag.py","lcmt_force_torque.py","lcmt_hydroelastic_contact_surface_for_viz.py","lcmt_hydroelastic_contact_surface_tri_for_viz.py","lcmt_hydroelastic_quadrature_per_point_data_for_viz.py","lcmt_iiwa_command.py","lcmt_iiwa_status.py","lcmt_iiwa_status_telemetry.py","lcmt_inverse_dynamics_debug_info.py","lcmt_jaco_command.py","lcmt_jaco_status.py","lcmt_joint_pd_override.py","lcmt_manipulator_plan_move_end_effector.py","lcmt_piecewise_polynomial.py","lcmt_plan_eval_debug_info.py","lcmt_planar_gripper_command.py","lcmt_planar_gripper_finger_command.py","lcmt_planar_gripper_finger_status.py","lcmt_planar_gripper_status.py","lcmt_planar_manipuland_status.py","lcmt_point_pair_contact_info_for_viz.py","lcmt_polynomial.py","lcmt_polynomial_matrix.py","lcmt_qp_controller_input.py","lcmt_qp_input.py","lcmt_quadrotor_input_t.py","lcmt_quadrotor_output_t.py","lcmt_resolved_contact.py","lcmt_robot_state.py","lcmt_schunk_wsg_command.py","lcmt_schunk_wsg_status.py","lcmt_scope_data.py","lcmt_simulation_command.py","lcmt_support_data.py","lcmt_viewer2_comms.py","lcmt_viewer_command.py","lcmt_viewer_draw.py","lcmt_viewer_geometry_data.py","lcmt_viewer_link_data.py","lcmt_viewer_load_robot.py","lcmt_whole_body_data.py","lcmt_zmp_com_observer_state.py","lcmt_zmp_data.py"],"python_site_packages_relpath":"lib/python3.6/site-packages","runfiles":{"drake":[".drake-find_resource-sentinel","common/resource_tool","examples/acrobot/Acrobot.sdf","examples/acrobot/Acrobot.urdf","examples/acrobot/Acrobot_no_collision.urdf","examples/atlas/package.xml","examples/atlas/sdf/block_angle_steps_1/model.sdf","examples/atlas/sdf/block_angle_steps_2/model.sdf","examples/atlas/sdf/block_level_steps_1/model.sdf","examples/atlas/sdf/block_level_steps_2/model.sdf","examples/atlas/sdf/cinder_block_2/materials/textures/cinder_block.png","examples/atlas/sdf/cinder_block_2/meshes/cinder_block.dae","examples/atlas/sdf/cinder_block_2/meshes/cinder_block.obj","examples/atlas/sdf/cinder_block_2/meshes/cinder_block.obj.mtl","examples/atlas/sdf/cinder_block_2/model-1_4.sdf","examples/atlas/sdf/cinder_block_2/model.sdf","examples/atlas/sdf/cinder_block_wide/meshes/cinder_block_wide.dae","examples/atlas/sdf/cinder_block_wide/meshes/cinder_block_wide.obj","examples/atlas/sdf/cinder_block_wide/meshes/cinder_block_wide.obj.mtl","examples/atlas/sdf/cinder_block_wide/model.sdf","examples/atlas/sdf/ground_plane/model-1_2.sdf","examples/atlas/sdf/ground_plane/model-1_3.sdf","examples/atlas/sdf/ground_plane/model-1_4.sdf","examples/atlas/sdf/ground_plane/model.sdf","examples/atlas/sdf/sun/model-1_2.sdf","examples/atlas/sdf/sun/model-1_3.sdf","examples/atlas/sdf/sun/model-1_4.sdf","examples/atlas/sdf/sun/model.sdf","examples/atlas/urdf/atlas_convex_hull.urdf","examples/atlas/urdf/atlas_minimal_contact.urdf","examples/atlas/urdf/block_hand.urdf","examples/atlas/urdf/door.urdf","examples/atlas/urdf/drill_frame.urdf","examples/atlas/urdf/materials/textures/atlas_DRC_1.png","examples/atlas/urdf/materials/textures/atlas_DRC_carbon_fiber.png","examples/atlas/urdf/materials/textures/atlas_DRC_dark_1.png","examples/atlas/urdf/materials/textures/atlas_cage_and_camera_diffuse_flat.jpg","examples/atlas/urdf/materials/textures/drc_extremities_diffuse.jpg","examples/atlas/urdf/materials/textures/drc_head_diffuse.png","examples/atlas/urdf/materials/textures/drc_labels_1.jpg","examples/atlas/urdf/materials/textures/drc_torso_head_diffuse.jpg","examples/atlas/urdf/materials/textures/extremities_diffuse.png","examples/atlas/urdf/materials/textures/extremities_diffuse_unplugged.jpg","examples/atlas/urdf/materials/textures/extremities_diffuse_unplugged_mit.jpg","examples/atlas/urdf/materials/textures/right_leg_diffuse_unplugged.jpg","examples/atlas/urdf/materials/textures/torso_diffuse.png","examples/atlas/urdf/materials/textures/torso_diffuse_unplugged.jpg","examples/atlas/urdf/materials/textures/torso_diffuse_unplugged_mit.jpg","examples/atlas/urdf/meshes/GRIPPER_OPEN_chull.obj","examples/atlas/urdf/meshes/head.obj","examples/atlas/urdf/meshes/head_camera.obj","examples/atlas/urdf/meshes/head_camera_chull.obj","examples/atlas/urdf/meshes/head_chull.obj","examples/atlas/urdf/meshes/l_clav.vtm","examples/atlas/urdf/meshes/l_clav/l_clav_0.vtp","examples/atlas/urdf/meshes/l_farm.vtm","examples/atlas/urdf/meshes/l_farm/l_farm_0.vtp","examples/atlas/urdf/meshes/l_foot.obj","examples/atlas/urdf/meshes/l_foot.vtm","examples/atlas/urdf/meshes/l_foot/l_foot_0.vtp","examples/atlas/urdf/meshes/l_foot_chull.obj","examples/atlas/urdf/meshes/l_hand.vtm","examples/atlas/urdf/meshes/l_hand/l_hand_0.vtp","examples/atlas/urdf/meshes/l_larm.vtm","examples/atlas/urdf/meshes/l_larm/l_larm_0.vtp","examples/atlas/urdf/meshes/l_lglut.obj","examples/atlas/urdf/meshes/l_lglut.vtm","examples/atlas/urdf/meshes/l_lglut/l_lglut_0.vtp","examples/atlas/urdf/meshes/l_lglut_chull.obj","examples/atlas/urdf/meshes/l_lleg.obj","examples/atlas/urdf/meshes/l_lleg.vtm","examples/atlas/urdf/meshes/l_lleg/l_lleg_0.vtp","examples/atlas/urdf/meshes/l_lleg_chull.obj","examples/atlas/urdf/meshes/l_scap.vtm","examples/atlas/urdf/meshes/l_scap/l_scap_0.vtp","examples/atlas/urdf/meshes/l_talus.obj","examples/atlas/urdf/meshes/l_talus.vtm","examples/atlas/urdf/meshes/l_talus/l_talus_0.vtp","examples/atlas/urdf/meshes/l_uarm.vtm","examples/atlas/urdf/meshes/l_uarm/l_uarm_0.vtp","examples/atlas/urdf/meshes/l_uglut.obj","examples/atlas/urdf/meshes/l_uglut.vtm","examples/atlas/urdf/meshes/l_uglut/l_uglut_0.vtp","examples/atlas/urdf/meshes/l_uglut_chull.obj","examples/atlas/urdf/meshes/l_uleg.obj","examples/atlas/urdf/meshes/l_uleg.vtm","examples/atlas/urdf/meshes/l_uleg/l_uleg_0.vtp","examples/atlas/urdf/meshes/l_uleg_chull.obj","examples/atlas/urdf/meshes/ltorso.obj","examples/atlas/urdf/meshes/ltorso.vtm","examples/atlas/urdf/meshes/ltorso/ltorso_0.vtp","examples/atlas/urdf/meshes/mtorso.obj","examples/atlas/urdf/meshes/mtorso.vtm","examples/atlas/urdf/meshes/mtorso/mtorso_0.vtp","examples/atlas/urdf/meshes/pelvis.obj","examples/atlas/urdf/meshes/pelvis.vtm","examples/atlas/urdf/meshes/pelvis/pelvis_0.vtp","examples/atlas/urdf/meshes/pelvis_chull.obj","examples/atlas/urdf/meshes/r_clav.obj","examples/atlas/urdf/meshes/r_clav.vtm","examples/atlas/urdf/meshes/r_clav/r_clav_0.vtp","examples/atlas/urdf/meshes/r_clav_chull.obj","examples/atlas/urdf/meshes/r_farm.obj","examples/atlas/urdf/meshes/r_farm.vtm","examples/atlas/urdf/meshes/r_farm/r_farm_0.vtp","examples/atlas/urdf/meshes/r_farm_chull.obj","examples/atlas/urdf/meshes/r_foot.obj","examples/atlas/urdf/meshes/r_foot.vtm","examples/atlas/urdf/meshes/r_foot/r_foot_0.vtp","examples/atlas/urdf/meshes/r_foot_chull.obj","examples/atlas/urdf/meshes/r_hand.obj","examples/atlas/urdf/meshes/r_hand.vtm","examples/atlas/urdf/meshes/r_hand/r_hand_0.vtp","examples/atlas/urdf/meshes/r_hand_chull.obj","examples/atlas/urdf/meshes/r_larm.obj","examples/atlas/urdf/meshes/r_larm.vtm","examples/atlas/urdf/meshes/r_larm/r_larm_0.vtp","examples/atlas/urdf/meshes/r_larm_chull.obj","examples/atlas/urdf/meshes/r_lglut.obj","examples/atlas/urdf/meshes/r_lglut.vtm","examples/atlas/urdf/meshes/r_lglut/r_lglut_0.vtp","examples/atlas/urdf/meshes/r_lglut_chull.obj","examples/atlas/urdf/meshes/r_lleg.obj","examples/atlas/urdf/meshes/r_lleg.vtm","examples/atlas/urdf/meshes/r_lleg/r_lleg_0.vtp","examples/atlas/urdf/meshes/r_lleg_chull.obj","examples/atlas/urdf/meshes/r_scap.obj","examples/atlas/urdf/meshes/r_scap.vtm","examples/atlas/urdf/meshes/r_scap/r_scap_0.vtp","examples/atlas/urdf/meshes/r_scap_chull.obj","examples/atlas/urdf/meshes/r_talus.obj","examples/atlas/urdf/meshes/r_talus.vtm","examples/atlas/urdf/meshes/r_talus/r_talus_0.vtp","examples/atlas/urdf/meshes/r_uarm.obj","examples/atlas/urdf/meshes/r_uarm.vtm","examples/atlas/urdf/meshes/r_uarm/r_uarm_0.vtp","examples/atlas/urdf/meshes/r_uarm_chull.obj","examples/atlas/urdf/meshes/r_uglut.obj","examples/atlas/urdf/meshes/r_uglut.vtm","examples/atlas/urdf/meshes/r_uglut/r_uglut_0.vtp","examples/atlas/urdf/meshes/r_uglut_chull.obj","examples/atlas/urdf/meshes/r_uleg.obj","examples/atlas/urdf/meshes/r_uleg.vtm","examples/atlas/urdf/meshes/r_uleg/r_uleg_0.vtp","examples/atlas/urdf/meshes/r_uleg_chull.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_0.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_0_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_0_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_0_chull.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_0_chull_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_0_chull_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_1_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_1_chull.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_1_chull_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_1_chull_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_2.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_2_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_2_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_2_chull.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_2_chull_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_2_chull_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_3.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_3_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_3_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_3_chull.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_3_chull_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/link_3_chull_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/palm.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/palm_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/palm_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/palm_chull.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/palm_chull_1.obj","examples/atlas/urdf/meshes/s-model_articulated/collision/palm_chull_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_0.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_0_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_0_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_0_chull.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_0_chull_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_0_chull_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_1_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_1_chull.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_1_chull_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_1_chull_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_2.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_2_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_2_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_2_chull.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_2_chull_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_2_chull_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_3.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_3_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_3_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_3_chull.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_3_chull_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/link_3_chull_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/palm.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/palm_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/palm_1_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/palm_chull.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/palm_chull_1.obj","examples/atlas/urdf/meshes/s-model_articulated/visual/palm_chull_1_1.obj","examples/atlas/urdf/meshes/utorso.obj","examples/atlas/urdf/meshes/utorso.vtm","examples/atlas/urdf/meshes/utorso/utorso_0.vtp","examples/atlas/urdf/meshes/utorso_chull.obj","examples/atlas/urdf/robotiq.urdf","examples/atlas/urdf/robotiq_box.urdf","examples/atlas/urdf/robotiq_simple.urdf","examples/atlas/urdf/robotiq_tendons.urdf","examples/atlas/urdf/valve_wall.urdf","examples/irb140/package.xml","examples/irb140/urdf/ATI_sensor.urdf","examples/irb140/urdf/irb_140.urdf","examples/irb140/urdf/irb_140_convhull.urdf","examples/irb140/urdf/irb_140_robotiq.urdf","examples/irb140/urdf/irb_140_robotiq_ati.urdf","examples/irb140/urdf/irb_140_robotiq_simple_ati.urdf","examples/irb140/urdf/meshes/ATI_sensor.obj","examples/irb140/urdf/meshes/ATI_sensor.stl","examples/irb140/urdf/meshes/ATI_sensor_chull.obj","examples/irb140/urdf/meshes/ATI_sensor_chull.stl","examples/irb140/urdf/meshes/base_link.obj","examples/irb140/urdf/meshes/base_link.stl","examples/irb140/urdf/meshes/base_link_chull.obj","examples/irb140/urdf/meshes/base_link_chull.stl","examples/irb140/urdf/meshes/link1.obj","examples/irb140/urdf/meshes/link1.stl","examples/irb140/urdf/meshes/link1_chull.obj","examples/irb140/urdf/meshes/link1_chull.stl","examples/irb140/urdf/meshes/link2.obj","examples/irb140/urdf/meshes/link2.stl","examples/irb140/urdf/meshes/link2_chull.obj","examples/irb140/urdf/meshes/link2_chull.stl","examples/irb140/urdf/meshes/link3.obj","examples/irb140/urdf/meshes/link3.stl","examples/irb140/urdf/meshes/link3_chull.obj","examples/irb140/urdf/meshes/link3_chull.stl","examples/irb140/urdf/meshes/link4.obj","examples/irb140/urdf/meshes/link4.stl","examples/irb140/urdf/meshes/link4_chull.obj","examples/irb140/urdf/meshes/link4_chull.stl","examples/irb140/urdf/meshes/link5.obj","examples/irb140/urdf/meshes/link5.stl","examples/irb140/urdf/meshes/link5_chull.obj","examples/irb140/urdf/meshes/link5_chull.stl","examples/irb140/urdf/meshes/link6.obj","examples/irb140/urdf/meshes/link6.stl","examples/irb140/urdf/meshes/link6_chull.obj","examples/irb140/urdf/meshes/link6_chull.stl","examples/kuka_iiwa_arm/iiwa_wsg_simulation","examples/kuka_iiwa_arm/kuka_plan_runner","examples/kuka_iiwa_arm/kuka_simulation","examples/kuka_iiwa_arm/models/desk/transcendesk55inch.sdf","examples/kuka_iiwa_arm/models/objects/big_robot_toy.urdf","examples/kuka_iiwa_arm/models/objects/black_box.urdf","examples/kuka_iiwa_arm/models/objects/block_for_pick_and_place.urdf","examples/kuka_iiwa_arm/models/objects/block_for_pick_and_place_large_size.urdf","examples/kuka_iiwa_arm/models/objects/block_for_pick_and_place_mid_size.urdf","examples/kuka_iiwa_arm/models/objects/folding_table.urdf","examples/kuka_iiwa_arm/models/objects/meshes/visual/big_robot_toy.obj","examples/kuka_iiwa_arm/models/objects/open_top_box.urdf","examples/kuka_iiwa_arm/models/objects/round_table.urdf","examples/kuka_iiwa_arm/models/objects/simple_cuboid.urdf","examples/kuka_iiwa_arm/models/objects/simple_cylinder.urdf","examples/kuka_iiwa_arm/models/objects/yellow_post.urdf","examples/kuka_iiwa_arm/models/table/extra_heavy_duty_table.sdf","examples/kuka_iiwa_arm/models/table/extra_heavy_duty_table_surface_only_collision.sdf","examples/manipulation_station/models/061_foam_brick.sdf","examples/manipulation_station/models/amazon_table_simplified.sdf","examples/manipulation_station/models/bin.sdf","examples/manipulation_station/models/cupboard.sdf","examples/manipulation_station/models/cylinder.sdf","examples/manipulation_station/models/sphere.sdf","examples/manipulation_station/models/thin_box.sdf","examples/manipulation_station/models/thin_cylinder.sdf","examples/multibody/cart_pole/cart_pole.sdf","examples/pendulum/Pendulum.urdf","examples/planar_gripper/planar_brick.sdf","examples/planar_gripper/planar_gripper.sdf","examples/pr2/models/pr2_description/meshes/base_v0/base.obj","examples/pr2/models/pr2_description/meshes/base_v0/base.stl","examples/pr2/models/pr2_description/meshes/base_v0/base_L.obj","examples/pr2/models/pr2_description/meshes/base_v0/base_L.stl","examples/pr2/models/pr2_description/meshes/base_v0/caster.obj","examples/pr2/models/pr2_description/meshes/base_v0/caster.stl","examples/pr2/models/pr2_description/meshes/base_v0/caster_L.obj","examples/pr2/models/pr2_description/meshes/base_v0/caster_L.stl","examples/pr2/models/pr2_description/meshes/base_v0/pr2_wheel.obj","examples/pr2/models/pr2_description/meshes/base_v0/pr2_wheel.stl","examples/pr2/models/pr2_description/meshes/base_v0/wheel.obj","examples/pr2/models/pr2_description/meshes/base_v0/wheel.stl","examples/pr2/models/pr2_description/meshes/forearm_v0/forearm.obj","examples/pr2/models/pr2_description/meshes/forearm_v0/forearm.stl","examples/pr2/models/pr2_description/meshes/forearm_v0/wrist_flex.obj","examples/pr2/models/pr2_description/meshes/forearm_v0/wrist_flex.stl","examples/pr2/models/pr2_description/meshes/forearm_v0/wrist_roll.obj","examples/pr2/models/pr2_description/meshes/forearm_v0/wrist_roll.stl","examples/pr2/models/pr2_description/meshes/forearm_v0/wrist_roll_L.obj","examples/pr2/models/pr2_description/meshes/forearm_v0/wrist_roll_L.stl","examples/pr2/models/pr2_description/meshes/gripper_v0/finger_tip_l.obj","examples/pr2/models/pr2_description/meshes/gripper_v0/finger_tip_l.stl","examples/pr2/models/pr2_description/meshes/gripper_v0/finger_tip_pad2_l.obj","examples/pr2/models/pr2_description/meshes/gripper_v0/finger_tip_pad2_l.stl","examples/pr2/models/pr2_description/meshes/gripper_v0/finger_tip_pad2_r.obj","examples/pr2/models/pr2_description/meshes/gripper_v0/finger_tip_pad2_r.stl","examples/pr2/models/pr2_description/meshes/gripper_v0/finger_tip_r.obj","examples/pr2/models/pr2_description/meshes/gripper_v0/finger_tip_r.stl","examples/pr2/models/pr2_description/meshes/gripper_v0/gripper_palm.obj","examples/pr2/models/pr2_description/meshes/gripper_v0/gripper_palm.stl","examples/pr2/models/pr2_description/meshes/gripper_v0/l_finger.obj","examples/pr2/models/pr2_description/meshes/gripper_v0/l_finger.stl","examples/pr2/models/pr2_description/meshes/gripper_v0/l_finger_tip.obj","examples/pr2/models/pr2_description/meshes/gripper_v0/l_finger_tip.stl","examples/pr2/models/pr2_description/meshes/gripper_v0/l_floating.obj","examples/pr2/models/pr2_description/meshes/gripper_v0/l_floating.stl","examples/pr2/models/pr2_description/meshes/gripper_v0/upper_finger_l.obj","examples/pr2/models/pr2_description/meshes/gripper_v0/upper_finger_l.stl","examples/pr2/models/pr2_description/meshes/gripper_v0/upper_finger_r.obj","examples/pr2/models/pr2_description/meshes/gripper_v0/upper_finger_r.stl","examples/pr2/models/pr2_description/meshes/head_v0/head_pan.obj","examples/pr2/models/pr2_description/meshes/head_v0/head_pan.stl","examples/pr2/models/pr2_description/meshes/head_v0/head_pan_L.obj","examples/pr2/models/pr2_description/meshes/head_v0/head_pan_L.stl","examples/pr2/models/pr2_description/meshes/head_v0/head_tilt.obj","examples/pr2/models/pr2_description/meshes/head_v0/head_tilt.stl","examples/pr2/models/pr2_description/meshes/head_v0/head_tilt_L.obj","examples/pr2/models/pr2_description/meshes/head_v0/head_tilt_L.stl","examples/pr2/models/pr2_description/meshes/sensors/kinect_v0/kinect_mount.stl","examples/pr2/models/pr2_description/meshes/shoulder_v0/shoulder_lift.obj","examples/pr2/models/pr2_description/meshes/shoulder_v0/shoulder_lift.stl","examples/pr2/models/pr2_description/meshes/shoulder_v0/shoulder_pan.obj","examples/pr2/models/pr2_description/meshes/shoulder_v0/shoulder_pan.stl","examples/pr2/models/pr2_description/meshes/shoulder_v0/shoulder_yaw.obj","examples/pr2/models/pr2_description/meshes/shoulder_v0/shoulder_yaw.stl","examples/pr2/models/pr2_description/meshes/shoulder_v0/upper_arm_roll.obj","examples/pr2/models/pr2_description/meshes/shoulder_v0/upper_arm_roll.stl","examples/pr2/models/pr2_description/meshes/shoulder_v0/upper_arm_roll_L.obj","examples/pr2/models/pr2_description/meshes/shoulder_v0/upper_arm_roll_L.stl","examples/pr2/models/pr2_description/meshes/tilting_laser_v0/hok_tilt.obj","examples/pr2/models/pr2_description/meshes/tilting_laser_v0/hok_tilt.stl","examples/pr2/models/pr2_description/meshes/tilting_laser_v0/tilting_hokuyo.obj","examples/pr2/models/pr2_description/meshes/tilting_laser_v0/tilting_hokuyo.stl","examples/pr2/models/pr2_description/meshes/tilting_laser_v0/tilting_hokuyo_L.obj","examples/pr2/models/pr2_description/meshes/tilting_laser_v0/tilting_hokuyo_L.stl","examples/pr2/models/pr2_description/meshes/torso_v0/torso.obj","examples/pr2/models/pr2_description/meshes/torso_v0/torso.stl","examples/pr2/models/pr2_description/meshes/torso_v0/torso_lift.obj","examples/pr2/models/pr2_description/meshes/torso_v0/torso_lift.stl","examples/pr2/models/pr2_description/meshes/torso_v0/torso_lift_L.obj","examples/pr2/models/pr2_description/meshes/torso_v0/torso_lift_L.stl","examples/pr2/models/pr2_description/meshes/upper_arm_v0/elbow_flex.obj","examples/pr2/models/pr2_description/meshes/upper_arm_v0/elbow_flex.stl","examples/pr2/models/pr2_description/meshes/upper_arm_v0/forearm_roll.obj","examples/pr2/models/pr2_description/meshes/upper_arm_v0/forearm_roll.stl","examples/pr2/models/pr2_description/meshes/upper_arm_v0/forearm_roll_L.obj","examples/pr2/models/pr2_description/meshes/upper_arm_v0/forearm_roll_L.stl","examples/pr2/models/pr2_description/meshes/upper_arm_v0/upper_arm.obj","examples/pr2/models/pr2_description/meshes/upper_arm_v0/upper_arm.stl","examples/pr2/models/pr2_description/urdf/pr2_simplified.urdf","examples/quadrotor/office.urdf","examples/quadrotor/quadrotor.urdf","examples/quadrotor/quadrotor_base.obj","examples/quadrotor/quadrotor_fla.urdf","examples/quadrotor/warehouse.sdf","examples/simple_four_bar/FourBar.sdf","examples/simple_four_bar/FourBar.urdf","examples/simple_four_bar/FourBar2.urdf","manipulation/models/allegro_hand_description/LICENSE.TXT","manipulation/models/allegro_hand_description/meshes/allegro.mtl","manipulation/models/allegro_hand_description/meshes/base_link.obj","manipulation/models/allegro_hand_description/meshes/base_link_left.obj","manipulation/models/allegro_hand_description/meshes/link_0.0.obj","manipulation/models/allegro_hand_description/meshes/link_1.0.obj","manipulation/models/allegro_hand_description/meshes/link_12.0_left.obj","manipulation/models/allegro_hand_description/meshes/link_12.0_right.obj","manipulation/models/allegro_hand_description/meshes/link_13.0.obj","manipulation/models/allegro_hand_description/meshes/link_14.0.obj","manipulation/models/allegro_hand_description/meshes/link_15.0.obj","manipulation/models/allegro_hand_description/meshes/link_15.0_tip.obj","manipulation/models/allegro_hand_description/meshes/link_2.0.obj","manipulation/models/allegro_hand_description/meshes/link_3.0.obj","manipulation/models/allegro_hand_description/meshes/link_3.0_tip.obj","manipulation/models/allegro_hand_description/package.xml","manipulation/models/allegro_hand_description/sdf/allegro_hand_description_left.sdf","manipulation/models/allegro_hand_description/sdf/allegro_hand_description_right.sdf","manipulation/models/allegro_hand_description/urdf/allegro_hand_description_left.urdf","manipulation/models/allegro_hand_description/urdf/allegro_hand_description_right.urdf","manipulation/models/franka_description/LICENSE","manipulation/models/franka_description/LICENSE.TXT","manipulation/models/franka_description/meshes/visual/finger.mtl","manipulation/models/franka_description/meshes/visual/finger.obj","manipulation/models/franka_description/meshes/visual/hand.mtl","manipulation/models/franka_description/meshes/visual/hand.obj","manipulation/models/franka_description/meshes/visual/link0.mtl","manipulation/models/franka_description/meshes/visual/link0.obj","manipulation/models/franka_description/meshes/visual/link1.mtl","manipulation/models/franka_description/meshes/visual/link1.obj","manipulation/models/franka_description/meshes/visual/link2.mtl","manipulation/models/franka_description/meshes/visual/link2.obj","manipulation/models/franka_description/meshes/visual/link3.mtl","manipulation/models/franka_description/meshes/visual/link3.obj","manipulation/models/franka_description/meshes/visual/link4.mtl","manipulation/models/franka_description/meshes/visual/link4.obj","manipulation/models/franka_description/meshes/visual/link5.mtl","manipulation/models/franka_description/meshes/visual/link5.obj","manipulation/models/franka_description/meshes/visual/link6.mtl","manipulation/models/franka_description/meshes/visual/link6.obj","manipulation/models/franka_description/meshes/visual/link7.mtl","manipulation/models/franka_description/meshes/visual/link7.obj","manipulation/models/franka_description/package.xml","manipulation/models/franka_description/urdf/hand.urdf","manipulation/models/franka_description/urdf/panda_arm.urdf","manipulation/models/franka_description/urdf/panda_arm_hand.urdf","manipulation/models/iiwa_description/LICENSE.TXT","manipulation/models/iiwa_description/iiwa7/iiwa7_no_collision.sdf","manipulation/models/iiwa_description/iiwa7/iiwa7_with_box_collision.sdf","manipulation/models/iiwa_description/iiwa7/link_0.obj","manipulation/models/iiwa_description/iiwa7/link_1.obj","manipulation/models/iiwa_description/iiwa7/link_2.obj","manipulation/models/iiwa_description/iiwa7/link_3.obj","manipulation/models/iiwa_description/iiwa7/link_4.obj","manipulation/models/iiwa_description/iiwa7/link_5.obj","manipulation/models/iiwa_description/iiwa7/link_6.obj","manipulation/models/iiwa_description/iiwa7/link_7.obj","manipulation/models/iiwa_description/iiwa_stack.LICENSE.txt","manipulation/models/iiwa_description/meshes/collision/link_0.obj","manipulation/models/iiwa_description/meshes/collision/link_1.obj","manipulation/models/iiwa_description/meshes/collision/link_2.obj","manipulation/models/iiwa_description/meshes/collision/link_3.obj","manipulation/models/iiwa_description/meshes/collision/link_4.obj","manipulation/models/iiwa_description/meshes/collision/link_5.obj","manipulation/models/iiwa_description/meshes/collision/link_6.obj","manipulation/models/iiwa_description/meshes/collision/link_7.obj","manipulation/models/iiwa_description/meshes/collision/link_7_polytope.obj","manipulation/models/iiwa_description/meshes/visual/band.obj","manipulation/models/iiwa_description/meshes/visual/kuka.obj","manipulation/models/iiwa_description/meshes/visual/link_0.obj","manipulation/models/iiwa_description/meshes/visual/link_1.obj","manipulation/models/iiwa_description/meshes/visual/link_2_grey.obj","manipulation/models/iiwa_description/meshes/visual/link_2_orange.obj","manipulation/models/iiwa_description/meshes/visual/link_3.obj","manipulation/models/iiwa_description/meshes/visual/link_4_grey.obj","manipulation/models/iiwa_description/meshes/visual/link_4_orange.obj","manipulation/models/iiwa_description/meshes/visual/link_5.obj","manipulation/models/iiwa_description/meshes/visual/link_6_grey.obj","manipulation/models/iiwa_description/meshes/visual/link_6_orange.obj","manipulation/models/iiwa_description/meshes/visual/link_7.obj","manipulation/models/iiwa_description/package.xml","manipulation/models/iiwa_description/sdf/iiwa14_no_collision.sdf","manipulation/models/iiwa_description/sdf/iiwa14_polytope_collision.sdf","manipulation/models/iiwa_description/urdf/dual_iiwa14_polytope_collision.urdf","manipulation/models/iiwa_description/urdf/iiwa14_no_collision.urdf","manipulation/models/iiwa_description/urdf/iiwa14_polytope_collision.urdf","manipulation/models/iiwa_description/urdf/iiwa14_primitive_collision.urdf","manipulation/models/iiwa_description/urdf/iiwa14_spheres_collision.urdf","manipulation/models/iiwa_description/urdf/iiwa14_spheres_dense_collision.urdf","manipulation/models/iiwa_description/urdf/iiwa14_spheres_dense_elbow_collision.urdf","manipulation/models/iiwa_description/urdf/planar_iiwa14_spheres_dense_elbow_collision.urdf","manipulation/models/jaco_description/LICENSE.TXT","manipulation/models/jaco_description/meshes/arm.obj","manipulation/models/jaco_description/meshes/arm_half_1.obj","manipulation/models/jaco_description/meshes/arm_half_2.obj","manipulation/models/jaco_description/meshes/arm_mico.obj","manipulation/models/jaco_description/meshes/base.obj","manipulation/models/jaco_description/meshes/finger_distal.obj","manipulation/models/jaco_description/meshes/finger_proximal.obj","manipulation/models/jaco_description/meshes/forearm.obj","manipulation/models/jaco_description/meshes/forearm_mico.obj","manipulation/models/jaco_description/meshes/hand_2finger.obj","manipulation/models/jaco_description/meshes/hand_3finger.obj","manipulation/models/jaco_description/meshes/ring_big.obj","manipulation/models/jaco_description/meshes/ring_small.obj","manipulation/models/jaco_description/meshes/shoulder.obj","manipulation/models/jaco_description/meshes/wrist.obj","manipulation/models/jaco_description/meshes/wrist_spherical_1.obj","manipulation/models/jaco_description/meshes/wrist_spherical_2.obj","manipulation/models/jaco_description/urdf/j2n6s300.urdf","manipulation/models/jaco_description/urdf/j2n6s300_col.urdf","manipulation/models/jaco_description/urdf/j2s7s300.urdf","manipulation/models/jaco_description/urdf/j2s7s300_arm.urdf","manipulation/models/jaco_description/urdf/j2s7s300_arm_sphere_collision.urdf","manipulation/models/jaco_description/urdf/j2s7s300_hand.urdf","manipulation/models/jaco_description/urdf/j2s7s300_hand_sphere_collision.urdf","manipulation/models/jaco_description/urdf/j2s7s300_sphere_collision.urdf","manipulation/models/wsg_50_description/LICENSE.TXT","manipulation/models/wsg_50_description/meshes/GUIDE_WSG50_110.obj","manipulation/models/wsg_50_description/meshes/WSG-FMF.obj","manipulation/models/wsg_50_description/meshes/WSG50_110.obj","manipulation/models/wsg_50_description/package.xml","manipulation/models/wsg_50_description/sdf/schunk_wsg_50.sdf","manipulation/models/wsg_50_description/sdf/schunk_wsg_50_ball_contact.sdf","manipulation/models/wsg_50_description/urdf/wsg_50_mesh_collision.urdf","manipulation/models/ycb/meshes/003_cracker_box_textured.mtl","manipulation/models/ycb/meshes/003_cracker_box_textured.obj","manipulation/models/ycb/meshes/003_cracker_box_textured.png","manipulation/models/ycb/meshes/004_sugar_box_textured.mtl","manipulation/models/ycb/meshes/004_sugar_box_textured.obj","manipulation/models/ycb/meshes/004_sugar_box_textured.png","manipulation/models/ycb/meshes/005_tomato_soup_can_textured.mtl","manipulation/models/ycb/meshes/005_tomato_soup_can_textured.obj","manipulation/models/ycb/meshes/005_tomato_soup_can_textured.png","manipulation/models/ycb/meshes/006_mustard_bottle_textured.mtl","manipulation/models/ycb/meshes/006_mustard_bottle_textured.obj","manipulation/models/ycb/meshes/006_mustard_bottle_textured.png","manipulation/models/ycb/meshes/009_gelatin_box_textured.mtl","manipulation/models/ycb/meshes/009_gelatin_box_textured.obj","manipulation/models/ycb/meshes/009_gelatin_box_textured.png","manipulation/models/ycb/meshes/010_potted_meat_can_textured.mtl","manipulation/models/ycb/meshes/010_potted_meat_can_textured.obj","manipulation/models/ycb/meshes/010_potted_meat_can_textured.png","manipulation/models/ycb/meshes/LICENSE.txt","manipulation/models/ycb/sdf/003_cracker_box.sdf","manipulation/models/ycb/sdf/004_sugar_box.sdf","manipulation/models/ycb/sdf/005_tomato_soup_can.sdf","manipulation/models/ycb/sdf/006_mustard_bottle.sdf","manipulation/models/ycb/sdf/009_gelatin_box.sdf","manipulation/models/ycb/sdf/010_potted_meat_can.sdf"]}}