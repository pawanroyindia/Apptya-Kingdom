using UnityEngine;
using UnityEngine.EventSystems;

namespace ApptyaKingdom
{
    /// <summary>Mobile-friendly bounded kingdom panning and pinch-zoom controls.</summary>
    public class ApptyaCameraController : MonoBehaviour
    {
        [SerializeField] float panSensitivity = 0.0025f;
        [SerializeField] float zoomSensitivity = 0.025f;
        [SerializeField] Vector2 horizontalBounds = new Vector2(13f, 13f);
        [SerializeField] float minDistance = 12f;
        [SerializeField] float maxDistance = 34f;
        [SerializeField] float minPitch = 22f;
        [SerializeField] float maxPitch = 58f;

        Vector3 focus = new Vector3(0f, 0f, 1f);
        float yaw;
        float pitch = 32f;
        float distance = 27f;
        Vector2 previousTouch;
        bool wasDragging;
        bool touchStartedOverUI;
        bool pinchBlockedByUI;
        bool wasPinching;

        void Start()
        {
            Vector3 offset = transform.position - focus;
            distance = Mathf.Clamp(offset.magnitude, minDistance, maxDistance);
            if (offset.sqrMagnitude > 0.01f)
            {
                yaw = Mathf.Atan2(offset.x, offset.z) * Mathf.Rad2Deg;
                pitch = Mathf.Clamp(Mathf.Atan2(offset.y, new Vector2(offset.x, offset.z).magnitude) * Mathf.Rad2Deg, minPitch, maxPitch);
            }
            ApplyCamera();
        }

        void LateUpdate()
        {
            if (Input.touchCount == 2)
            {
                wasDragging = false;
                wasPinching = true;
                Touch a = Input.GetTouch(0);
                Touch b = Input.GetTouch(1);
                // Do not zoom the world while a two-finger gesture is interacting with HUD controls.
                if (EventSystem.current != null &&
                    (EventSystem.current.IsPointerOverGameObject(a.fingerId) ||
                     EventSystem.current.IsPointerOverGameObject(b.fingerId)))
                    pinchBlockedByUI = true;
                if (pinchBlockedByUI) return;
                Vector2 aPrev = a.position - a.deltaPosition;
                Vector2 bPrev = b.position - b.deltaPosition;
                float previousGap = Vector2.Distance(aPrev, bPrev);
                float currentGap = Vector2.Distance(a.position, b.position);
                distance = Mathf.Clamp(distance - (currentGap - previousGap) * zoomSensitivity, minDistance, maxDistance);
                ApplyCamera();
                return;
            }

            if (Input.touchCount == 1)
            {
                Touch t = Input.GetTouch(0);
                // Reset the drag origin when one finger remains after a pinch, otherwise
                // the stale pre-pinch position can cause a sudden camera jump.
                if (wasPinching)
                {
                    previousTouch = t.position;
                    touchStartedOverUI = pinchBlockedByUI;
                    wasPinching = false;
                    return;
                }
                if (t.phase == TouchPhase.Began)
                {
                    previousTouch = t.position;
                    touchStartedOverUI = EventSystem.current != null && EventSystem.current.IsPointerOverGameObject(t.fingerId);
                }
                else if (t.phase == TouchPhase.Moved && !touchStartedOverUI && !pinchBlockedByUI)
                {
                    Vector2 delta = t.position - previousTouch;
                    Pan(delta);
                    previousTouch = t.position;
                }
                return;
            }
            touchStartedOverUI = false;
            pinchBlockedByUI = false;
            wasPinching = false;

            // Mouse fallback makes the camera easy to test in the Unity Editor.
            if (Input.GetMouseButtonDown(0))
            {
                previousTouch = Input.mousePosition;
                wasDragging = EventSystem.current == null || !EventSystem.current.IsPointerOverGameObject();
            }
            if (Input.GetMouseButton(0) && wasDragging)
            {
                Vector2 current = Input.mousePosition;
                Vector2 delta = current - previousTouch;
                Pan(delta);
                previousTouch = current;
            }
            if (Input.GetMouseButtonUp(0)) wasDragging = false;
            float scroll = Input.mouseScrollDelta.y;
            bool mouseOverUI = EventSystem.current != null && EventSystem.current.IsPointerOverGameObject();
            if (!mouseOverUI && Mathf.Abs(scroll) > 0.01f)
            {
                distance = Mathf.Clamp(distance - scroll, minDistance, maxDistance);
                ApplyCamera();
            }
        }

        void Pan(Vector2 screenDelta)
        {
            // Move parallel to the ground plane; clamp the focus so repeated drags cannot
            // send the kingdom off-screen or leave the playable valley behind.
            Quaternion heading = Quaternion.Euler(0f, yaw, 0f);
            Vector3 right = heading * Vector3.right;
            Vector3 forward = heading * Vector3.forward;
            float scale = Mathf.Max(1f, distance) * panSensitivity;
            focus += (-right * screenDelta.x - forward * screenDelta.y) * scale;
            focus.x = Mathf.Clamp(focus.x, -horizontalBounds.x, horizontalBounds.x);
            focus.z = Mathf.Clamp(focus.z, -horizontalBounds.y, horizontalBounds.y);
            ApplyCamera();
        }

        void ApplyCamera()
        {
            Quaternion rotation = Quaternion.Euler(pitch, yaw, 0f);
            transform.position = focus + rotation * new Vector3(0f, 0f, -distance);
            transform.rotation = rotation;
        }
    }
}